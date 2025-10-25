import { GlobalDate } from "../services/GlobalDate"; // 确保路径正确
import { AppStorageV2} from "@kit.ArkUI";
import RdbUtils from "../services/EventStore";
import CalendarEvent from "../model/Event";

@ComponentV2
export struct WeekView {
  // 连接到全局状态 GlobalDate
  @Local globalDate: GlobalDate = AppStorageV2.connect(GlobalDate, 'GLOBAL_DATE', () => new GlobalDate())!
  pathStack:NavPathStack = AppStorageV2.connect(NavPathStack, 'NAV_PATH_STACK', () => new NavPathStack())!
  @Local CalendarRDB: RdbUtils = AppStorageV2.connect(RdbUtils, 'CALENDAR_RDB', () => new RdbUtils())!
  private weekdayLabels: string[] = ['日', '一', '二', '三', '四', '五', '六'];

  aboutToAppear()
  {
    this.CalendarRDB.getEventsOnSelectedDay(this.globalDate.year,this.globalDate.month,this.globalDate.selectedDate.getDate())
  }

  private getLunarDayText(lunarDay: number): string {
    const chineseDay = [
      "", "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
      "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
      "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
    ]
    return chineseDay[lunarDay];
  }

  private getLunarMonthText(lunarMonth: number): string {
    const chineseMonth = ["正月","二月","三月","四月","五月","六月","七月","八月","九月","十月","冬月","腊月"];
    return chineseMonth[lunarMonth - 1];
  }

  private isSelected(day: number | undefined): boolean {
    if (day === undefined) {
      return false;
    }
    const isSameYearMonth = this.globalDate.selectedDate.getFullYear() === this.globalDate.year && this.globalDate.selectedDate.getMonth()+1 === this.globalDate.month;
    const isSameDay = this.globalDate.selectedDate.getDate() === day;
    return isSameYearMonth && isSameDay;
  }

  private select(day: number | undefined) {
    if (day === undefined) return;
    if(this.isCurrentMonthDay(day)===false)
    {
      const currentDay = this.globalDate.selectedDate.getDate();
      // 如果日期是 1 到 15，并且选中日期是本月月初，则可能是下个月的日期
      if (day <= 15 && currentDay > 20) {
        this.globalDate.month++
        if(this.globalDate.month>=13)
        {
          this.globalDate.year++
          this.globalDate.month=1
        }
        this.globalDate.selectedDate=new Date(this.globalDate.year,this.globalDate.month-1,day)
      }
      // 如果日期是 20 到 31，并且选中日期是本月月末，则可能是上个月的日期
      if (day >= 20 && currentDay < 15) {
        this.globalDate.month--
        if(this.globalDate.month<=0)
        {
          this.globalDate.year--
          this.globalDate.month=12
        }
        this.globalDate.selectedDate=new Date(this.globalDate.year,this.globalDate.month-1,day)
      }
      this.globalDate.updateMonth(this.globalDate.year,this.globalDate.month)
      this.globalDate.updateCurrentWeekData()
    }
    else
    {
      // 假设被点击的日期是本月日期
      let newDate = new Date(this.globalDate.year, this.globalDate.month-1, day);
      this.globalDate.selectedDate = newDate;
    }
    this.CalendarRDB.getEventsOnSelectedDay(this.globalDate.year,this.globalDate.month,this.globalDate.selectedDate.getDate())
  }

  private isToday(day: number | undefined): boolean {
    const today = new Date();
    return day !== undefined &&
      this.globalDate.year === today.getFullYear() &&
      this.globalDate.month === today.getMonth() + 1 &&
      day === today.getDate();
  }

  @Builder
  EventList()
  {
    List({space:10})
    {
      ForEach(this.CalendarRDB.SelectedDayEvents,(item:CalendarEvent,index:number)=>{
        ListItem()
        {
          Column()
          {
            Row()
            {
              Column()
              {
                Text(`${item.startHour.toString().padStart(2, '0')}:${item.startMinute.toString().padStart(2, '0')}`)
                  .fontSize(15)
                Text(`${item.endHour.toString().padStart(2, '0')}:${item.endMinute.toString().padStart(2, '0')}`)
                  .fontSize(15)
                  .fontColor('#C7C7C7')
              }
              Text("|")
                .fontWeight(FontWeight.Bolder)
                .margin(10)
                .fontColor('#4CA0D5')
              Column()
              {
                Text(`${item.title}`)
                  .fontSize(18)
                Text(`${item.location}`)
                  .fontSize(15)
                  .fontColor('#6B6B6B')
              }
            }
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
        }
        .onClick(()=>{
          this.pathStack.replacePathByName("EventLayout",{ event: item },false)
        })
      })
    }
    .width('95%')
    .height('100%')
    .padding({ left: 16, right: 16 })
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .divider({strokeWidth:1,color:'#E6E6E6'})
    .backgroundColor(Color.White)
    .padding(15)
    .borderRadius(25)
  }


  build() {
    Column() {
      Row() {
        Blank()
      }
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })

      // 星期标签
      GridRow({ columns: 7 }) {
        ForEach(this.weekdayLabels, (w: string) => {
          GridCol() {
            Text(w)
              .fontSize(12)
              .fontColor('#666666')
              .margin({ bottom: 8 })
          }
          .alignSelf(ItemAlign.Center)
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      // 日期主体（周）
      GridRow({ columns: 7 }) {
        ForEach(this.globalDate.currentWeek, (day: number | undefined,index:number) => {
          GridCol() {
              Stack() {
                // 选中的今天 (蓝色圆圈)
                if (this.isSelected(day) && this.isToday(day)) {
                  Circle()
                    .width(34)
                    .height(34)
                    .fill('#0B58F4')
                }
                // 选中的非今天 (白色圆圈带蓝边)
                else if (this.isSelected(day)) {
                  Circle()
                    .width(34)
                    .height(34)
                    .fill(Color.White)
                    .stroke('#0B58F4')
                    .strokeWidth(1)
                }

                Column()
                {
                  Text(`${day}`)
                    .fontSize(16)
                    .fontColor(
                      this.isSelected(day) && this.isToday(day) ? Color.White : // 选中的今天
                        (this.isToday(day) ? '#0B58F4' : Color.Black) // 今天的日期（未选中）
                    )
                    .opacity(this.isCurrentMonthDay(day) ? 1.0 : 0.4)
                  Text(`${this.globalDate.currentLunarWeek[index]?.lunarDay == 1 ? this.getLunarMonthText(this.globalDate.currentLunarWeek[index]?.lunarMonth) : this.getLunarDayText(this.globalDate.currentLunarWeek[index]?.lunarDay)}`)
                    .fontSize(10)
                    .fontColor(
                      this.isSelected(day) && this.isToday(day) ? Color.White : // 选中的今天
                        (this.isToday(day) ? '#0B58F4' : Color.Black) // 今天的日期（未选中）
                    )
                    .opacity(this.isCurrentMonthDay(day) ? 1.0 : 0.4)
                }
              }
              .width('100%')
              .height(44)
              .align(Alignment.Center)
              .onClick(() => this.select(day))
          }
          .alignSelf(ItemAlign.Center)
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      Text(`${this.globalDate.selectedDate.getFullYear()}年${this.globalDate.selectedDate.getMonth() + 1}月${this.globalDate.selectedDate.getDate()}日 的日程`)
        .fontSize(14)
        .fontColor('#666666')
        .margin(12)

      if(this.globalDate.isShowDatePicker===false)
      {
        this.EventList()
      }
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 辅助函数：判断给定日期是否属于 GlobalDate 当前显示的月份
   * （用于调整非本月日期的颜色，例如上个月末尾和下个月开头）
   */
  private isCurrentMonthDay(day: number): boolean {
    // 假设 GlobalDate 已经同步到 selectedDate 的月份
    const currentDay = this.globalDate.selectedDate.getDate();

    // 如果日期是 1 到 15，并且选中日期是本月月初，则可能是下个月的日期
    if (day <= 15 && currentDay > 20) {
      return false;
    }
    // 如果日期是 20 到 31，并且选中日期是本月月末，则可能是上个月的日期
    if (day >= 20 && currentDay < 15) {
      return false;
    }
    // 简单的判断：如果不是极端情况，认为是本月日期
    return true;
  }
}