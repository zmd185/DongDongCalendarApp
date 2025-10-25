import { GlobalDate } from "../services/GlobalDate";
import { AppStorageV2} from "@kit.ArkUI";
import CalendarEvent from "../model/Event";
import RdbUtils from "../services/EventStore";

@ComponentV2
export struct MonthView {
  pathStack:NavPathStack = AppStorageV2.connect(NavPathStack, 'NAV_PATH_STACK', () => new NavPathStack())!
  @Local CalendarRDB: RdbUtils = AppStorageV2.connect(RdbUtils, 'CALENDAR_RDB', () => new RdbUtils())!
  @Local globalDate: GlobalDate = AppStorageV2.connect(GlobalDate, 'GLOBAL_DATE', () => new GlobalDate())!
  @Local rowCount:number=this.globalDate.rowCount;
  @Local events:Array<CalendarEvent>=[]

  private weekdayLabels: string[] = ['日', '一', '二', '三', '四', '五', '六'];

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

    const isSameYearMonth =
      this.globalDate.selectedDate.getFullYear() === this.globalDate.year &&
        this.globalDate.selectedDate.getMonth()+1  === this.globalDate.month;

    const isSameDay = this.globalDate.selectedDate.getDate() === day;
    return isSameYearMonth && isSameDay;
  }

  private select(day: number | undefined,currentMonth:boolean) {
    if (day !== undefined) {
      if(currentMonth)
      {
        this.globalDate.selectedDate = new Date(this.globalDate.year, this.globalDate.month-1, day);
      }
      else
      {
        //上一个月
        if(day<=31&&day>=25)
        {
          this.globalDate.month--
          if(this.globalDate.month<=0)
          {
            this.globalDate.year--
            this.globalDate.month=12
          }
          this.globalDate.selectedDate = new Date(this.globalDate.year, this.globalDate.month-1, day);
        }
        if(day>=1&&day<=7)
        {
          this.globalDate.month++
          if(this.globalDate.month>=13)
          {
            this.globalDate.year++
            this.globalDate.month=1
          }
          this.globalDate.selectedDate = new Date(this.globalDate.year, this.globalDate.month-1, day);
        }
      }
    }
    this.globalDate.updateMonth(this.globalDate.year,this.globalDate.month)
    this.globalDate.updateCurrentWeekData()
    this.CalendarRDB.getEventsOnSelectedDay(this.globalDate.year,this.globalDate.month,this.globalDate.selectedDate.getDate())
  }

  private isToday(day: number | undefined): boolean {
    const today = new Date();
    return day !== undefined &&
      this.globalDate.year === today.getFullYear() &&
      this.globalDate.month === today.getMonth() + 1 &&
      day === today.getDate();
  }

  aboutToAppear()
  {
    this.CalendarRDB.getEventsOnSelectedDay(this.globalDate.year,this.globalDate.month,this.globalDate.selectedDate.getDate())

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

      Column() {
        ForEach(this.globalDate.rows, (row: Array<number | undefined>,rowIndex:number) => {
          GridRow({ columns: 7 }) {
            ForEach(row, (day: number | undefined,colIndex:number) => {
              GridCol() {
                if (rowIndex*7+colIndex>=this.globalDate.startIndex&&rowIndex*7+colIndex<=this.globalDate.endIndex)
                {
                  Stack()
                  {
                    // 选中的今天 (蓝色圆圈)
                    if (this.isSelected(day) && this.isToday(day))
                    {
                      Circle()
                        .width(34)
                        .height(34)
                        .fill('#0B58F4')
                    }
                    // 选中的非今天 (白色圆圈带蓝边)
                    else if (this.isSelected(day))
                    {
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
                      Text(this.globalDate.lunarRows[rowIndex][colIndex]?.lunarDay == 1 ? this.getLunarMonthText(this.globalDate.lunarRows[rowIndex][colIndex]?.lunarMonth) : this.getLunarDayText(this.globalDate.lunarRows[rowIndex][colIndex]?.lunarDay))
                        .fontSize(10)
                        .fontColor(
                          this.isSelected(day) && this.isToday(day) ? Color.White : // 选中的今天
                            (this.isToday(day) ? '#0B58F4' : Color.Black) // 今天的日期（未选中）
                        )
                    }

                  }
                  .width('100%')
                  .height(44)
                  .align(Alignment.Center)
                  .onClick(() => this.select(day,true))
                }
                else {
                  Stack()
                  {
                      Text(`${day}`)
                        .height(44)
                        .fontSize(16)
                        .fontColor('#C1C2C4')
                        .margin({bottom:12})
                      Text(this.globalDate.lunarRows[rowIndex][colIndex]?.lunarDay == 1 ? this.getLunarMonthText(this.globalDate.lunarRows[rowIndex][colIndex]?.lunarMonth) : this.getLunarDayText(this.globalDate.lunarRows[rowIndex][colIndex]?.lunarDay))
                        .fontSize(10)
                        .fontColor('#C1C2C4')
                        .margin({top:20})

                  }.width('100%')
                  .height(44)
                  .align(Alignment.Center)
                  .onClick(() => this.select(day,false))
                }
              }
              .alignSelf(ItemAlign.Center)
            })
          }
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      Text(`${this.globalDate.selectedDate.getFullYear()}年${this.globalDate.selectedDate.getMonth()+1}月${this.globalDate.selectedDate.getDate()}日 的日程`)
        .fontSize(14)
        .fontColor('#666666')
        .margin(12)

      if(this.globalDate.isShowDatePicker===false)
      {
        this.EventList()
      }

    }
    .backgroundColor('#F2F3F7')
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
    .width('100%')
    .height('100%')
  }
}
