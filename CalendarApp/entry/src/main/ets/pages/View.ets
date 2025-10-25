import { CalendarTabs } from '../ui/CalendarTabs';
import { GlobalDate } from '../services/GlobalDate';
import { AppStorageV2 } from '@kit.ArkUI';
import RdbUtils from '../services/EventStore';
import reminderService from '../services/ReminderService';

@Builder
export function ViewBuilder()
{
  ViewEditor()
}

@ComponentV2
struct ViewEditor
{
  pathStack:NavPathStack = AppStorageV2.connect(NavPathStack, 'NAV_PATH_STACK', () => new NavPathStack())!
  reminderService: reminderService = AppStorageV2.connect(reminderService, 'REMINDER_SERVICE', () => new reminderService())!

  @Local CalendarRDB: RdbUtils = AppStorageV2.connect(RdbUtils, 'CALENDAR_RDB', () => new RdbUtils())!
  @Local globalDate: GlobalDate = AppStorageV2.connect(GlobalDate, 'GLOBAL_DATE', () => new GlobalDate())!;

  @Local tempYear:number=0
  @Local tempMonth:number=0
  @Local tempDay:number=0
  private weekdayLabels: string[] = ['日', '一', '二', '三', '四', '五', '六'];

  private monthText(): string {
    return `${this.globalDate.year}年${this.globalDate.month}月`;
  }

  @Builder
  showDatePicker()
  {
    Column()
    {
      Text(`${this.globalDate.year}年${this.globalDate.month}月${this.globalDate.selectedDate.getDate()}日星期${this.weekdayLabels[this.globalDate.selectedDate.getDay()]}`)
        .fontSize(23)
        .fontWeight(FontWeight.Bold)

      DatePicker({
        start: new Date('1970-1-1'),
        end: new Date('2100-1-1'),
        selected: new Date(this.globalDate.year,this.globalDate.month-1,this.globalDate.selectedDate.getDate())
      })
        .disappearTextStyle({ color: '#ff182431', font: { size: 15, weight: FontWeight.Lighter } })
          //选择器未选中且不在边缘的文本样式
        .textStyle({ color: Color.Black, font: { size: 20, weight: FontWeight.Normal } })//
          //选中文本样式
        .selectedTextStyle({ color: Color.Blue, font: { size: 30 } })
        .onDateChange((value: Date) => {
          this.tempYear=value.getFullYear()
          this.tempMonth=value.getMonth()+1
          this.tempDay=value.getDate()

        })

      Row()
      {
        Button('取消')
          .backgroundColor(Color.Transparent)
          .fontColor(Color.Blue)
          .borderRadius(0)
          .borderWidth(0)
          .padding(0)
          .fontSize(23)
          .margin(50)
          .fontWeight(FontWeight.Normal)
          .onClick(()=>{
            this.globalDate.isShowDatePicker=false
          })
        Text('|')
          .fontSize(15)
          .fontColor('#DBDBDB')
        Button('确定')
          .backgroundColor(Color.Transparent)
          .fontColor(Color.Blue)
          .borderRadius(0)
          .borderWidth(0)
          .padding(0)
          .fontSize(23)
          .margin(50)
          .fontWeight(FontWeight.Normal)
          .onClick(()=>{
            this.globalDate.year=this.tempYear
            this.globalDate.month=this.tempMonth
            this.globalDate.selectedDate=new Date(this.tempYear,this.tempMonth-1,this.tempDay)
            this.globalDate.isShowDatePicker = false
            this.globalDate.updateMonth(this.globalDate.year,this.globalDate.month)
            this.globalDate.updateCurrentWeekData()
            this.CalendarRDB.getEventsOnSelectedDay(this.globalDate.year,this.globalDate.month,this.globalDate.selectedDate.getDate())
          })
      }
    }
    .position({ y: "55%" })
  }

  aboutToAppear(): void {
    if(this.reminderService.isInit===false)
    {
      this.reminderService.init()
      this.reminderService.isInit=true
    }

  }

  build()
  {
    NavDestination()
    {
      Stack() {
        Column() {
          // Header bar
          Row() {
            Text('<')
              .fontSize(22)
              .onClick(() => {
                let newMonth = this.globalDate.month;
                let newYear = this.globalDate.year;
                if (newMonth === 1) {
                  newMonth = 12;
                  newYear -= 1;
                } else {
                  newMonth -= 1;
                }
                this.globalDate.selectedDate=new Date(newYear,newMonth-1,this.globalDate.selectedDate.getDate())
                this.globalDate.updateMonth(newYear, newMonth);
                this.globalDate.updateCurrentWeekData()
                this.CalendarRDB.getEventsOnSelectedDay(this.globalDate.year,this.globalDate.month,this.globalDate.selectedDate.getDate())
              })
              .padding({ right: 7 })

            Text(this.monthText())
              .fontSize(22)
              .fontWeight(FontWeight.Medium)
              .onClick(()=>{this.globalDate.isShowDatePicker=true})


              Text('>')
                .fontSize(22)
                .onClick(() => {
                  let newMonth = this.globalDate.month;
                  let newYear = this.globalDate.year;
                  if (newMonth === 12) {
                    newMonth = 1;
                    newYear += 1;
                  } else {
                    newMonth += 1;
                  }
                  this.globalDate.selectedDate=new Date(newYear,newMonth-1,this.globalDate.selectedDate.getDate())
                  this.globalDate.updateMonth(newYear, newMonth);
                  this.globalDate.updateCurrentWeekData()
                  this.CalendarRDB.getEventsOnSelectedDay(this.globalDate.year,this.globalDate.month,this.globalDate.selectedDate.getDate())
                })
                .padding({ left: 7 })

          }
          .padding(16)

          CalendarTabs()
            .layoutWeight(1)
            .width('100%')
            .height('100%')
        }
        .width('100%')
        .height('100%')

        if(this.globalDate.isShowDatePicker)
        {
          this.showDatePicker()
        }

        // Floating Add Button
        Button('+')
          .width(56)
          .height(56)
          .fontSize(40)
          .fontColor(Color.White)
          .fontFamily("sans-serif")
          .backgroundColor('#3F6FF0')
          .position({ y: "93%", x: "80%" })
          .onClick(()=>{ this.pathStack.replacePathByName("EventEditor",null,false)})
      }
      .width('100%')
      .height('100%')
    }
    .backgroundColor('#F2F3F7')
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
    .onReady((context:NavDestinationContext)=>{
      this.pathStack=context.pathStack

    })
  }
}

