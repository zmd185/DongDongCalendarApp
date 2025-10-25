import { AppStorageV2 } from "@kit.ArkUI"
import RdbUtils from "../services/EventStore";
import { GlobalDate } from "../services/GlobalDate"
import { ValuesBucket } from "@kit.ArkData";
import CalendarEvent from "../model/Event";
import reminderService from "../services/ReminderService";

interface isUpdate
{
  isUpdate:boolean
  event:CalendarEvent
}

@Builder
export function EventEditorBuilder() {
  EventEditor()
}

@ComponentV2
struct EventEditor {
  pathStack: NavPathStack = AppStorageV2.connect(NavPathStack, 'NAV_PATH_STACK', () => new NavPathStack())!
  CalendarRDB: RdbUtils = AppStorageV2.connect(RdbUtils, 'CALENDAR_RDB', () => new RdbUtils())!
  reminderService: reminderService = AppStorageV2.connect(reminderService, 'REMINDER_SERVICE', () => new reminderService())!

  @Local globalDate: GlobalDate = AppStorageV2.connect(GlobalDate, 'GLOBAL_DATE', () => new GlobalDate())!;
  @Local isUpdate:boolean=false
  @Local event:CalendarEvent|null=null
  @Local eventTitle: string = ''
  @Local eventLocation:string = ''

  @Local year: number = this.globalDate.year
  @Local month: number = this.globalDate.month
  @Local date: number = this.globalDate.selectedDate.getDate()
  @Local dayOfWeek:number = new Date(this.year, this.month - 1, this.date).getDay()
  @Local startHour: number = new Date().getHours()
  @Local startMinute: number = new Date().getMinutes()
  @Local endHour: number = this.startHour+1
  @Local endMinute: number = this.startMinute
  @Local reminder:boolean=true
  @Local advanceMinutes:string='15'
  @Local allDay:boolean=false

  @Local showTimePicker:boolean=false
  @Local isStart:boolean=true
  @Local tempHour: number = 0
  @Local tempMinute: number = 0
  private weekdayLabels: string[] = ['日', '一', '二', '三', '四', '五', '六'];

  private saveEvent():void
  {
    if(this.isUpdate)
    {
      if(this.event)
      {
        this.updateEvent(this.event?.id)
      }
    }
    else
    {
      const valueBucket :ValuesBucket= {
        'title': this.eventTitle,
        'location': this.eventLocation,
        'year': this.year,
        'month':this.month,
        'date': this.date,
        'startHour': this.startHour,
        'startMinute': this.startMinute,
        'endHour': this.endHour,
        'endMinute': this.endMinute,
        'reminder': this.reminder?1:0,
        'allDay':this.allDay?1:0,
        'advanceMinutes':Number(this.advanceMinutes),
      };
      RdbUtils.insert('EVENTS', valueBucket)
        .then(()=>{this.reminderService.init()})
        .catch((error:Error) => {
          console.log(error.message)
        })
    }
  }

  private updateEvent(id:number)
  {
    const valueBucket :ValuesBucket= {
      'title': this.eventTitle,
      'location': this.eventLocation,
      'year': this.year,
      'month':this.month,
      'date': this.date,
      'startHour': this.startHour,
      'startMinute': this.startMinute,
      'endHour': this.endHour,
      'endMinute': this.endMinute,
      'reminder': this.reminder?1:0,
      'allDay':this.allDay?1:0,
      'advanceMinutes':Number(this.advanceMinutes),
    };
    RdbUtils.updateById(id, valueBucket)
      .then(() => {
        this.reminderService.updateReminder(id)
      }).catch((err:Error) => {
        console.log(err.message)
    })
  }

  aboutToAppear() {
    // 自动向上取整到最近半小时
    if (this.startMinute > 0 && this.startMinute < 30) {
      this.startMinute = 30
    }
    else if (this.startMinute >= 30) {
      this.startHour++
      this.startMinute = 0

      // 日期溢出处理
      if (this.startHour >= 24) {
        this.startHour = 0
      }
    }
    this.endHour=this.startHour+1
    this.endMinute=this.startMinute
    if(this.endHour>=24)
    {
      this.endHour=24
      this.endMinute=0
    }
  }

  @Builder
  showTimePickerLayout(hour:number,minute:number)
  {
    Column()
    {
      Text(`${this.year}年${this.month}月${this.date}日星期${this.weekdayLabels[this.dayOfWeek]}`)
        .fontSize(23)
        .fontWeight(FontWeight.Bold)
      TimePicker({
        //显示秒    默认显示时分
        format: TimePickerFormat.HOUR_MINUTE,
        //默认指定时间
        selected: new Date(this.year,this.month-1,this.date,hour,minute),
      })//
        //设置时分秒前面是否显示0   12小时制 时默认为numeric即不显示0，，24小时制默认显示
        .dateTimeOptions({})//
          //是否启用循环模式
        .loop(true)//
          // 改变显示时制  false 12小时制  true 24小时制
        .useMilitaryTime(true)
        .disappearTextStyle({ color: '#ff182431', font: { size: 15, weight: FontWeight.Lighter } })
          //选择器未选中且不在边缘的文本样式
        .textStyle({ color: Color.Black, font: { size: 20, weight: FontWeight.Normal } })//
          //选中文本样式
        .selectedTextStyle({ color: Color.Blue, font: { size: 30 } })
        .onChange((value: TimePickerResult) => {
          this.tempHour = value.hour
          this.tempMinute = value.minute
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
            this.showTimePicker=false
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
            if (this.isStart) {
              this.startHour = this.tempHour
              this.startMinute = this.tempMinute
              this.endHour=this.startHour+1
              if(this.endHour>=24)
              {
                this.endHour=24
                this.endMinute=0
              }
            } else {
              if(this.tempHour<this.startHour||(this.tempHour==this.startHour&&this.tempMinute<=this.startMinute)){}
              else
              {
                this.endHour = this.tempHour
                this.endMinute = this.tempMinute
              }
            }
            this.showTimePicker = false
          })
      }
    }
    .position({ y: "55%" })
  }


  build() {
    NavDestination() {
      // 顶部标题栏
      Row() {
        Image($r('app.media.xmark'))
          .width(30)
          .margin(15)
          .fillColor('#2B2C2E')
          .onClick(()=>{
            if(this.isUpdate)
            {
              this.pathStack.replacePathByName("EventLayout",{event:this.event},false)
            }
            else
            {
              this.pathStack.replacePathByName("View",null,false)
            }
          })
        Text(this.isUpdate?"编辑日程":"新建日程")
          .layoutWeight(1)
          .fontSize(30)
          .fontColor('#2B2C2E')
          .fontWeight(FontWeight.Bold)
        Image($r("app.media.checkmark"))
          .width(30)
          .fillColor(this.eventTitle.trim() === '' ? '#A3A4A6' : '#2B2C2E')
          .margin(15)
          .onClick(() => {
            if (this.eventTitle.trim() === '') {
              return
            }
            this.saveEvent()
            this.pathStack.replacePathByName("View",null,false)
          })
      }
      .margin({ top: 10 })
      .width('100%')

      // 主体输入部分
      List({space:10}) {
        // 标题输入
        ListItem() {
          Row() {
            Image($r('app.media.pencil_line_1'))
              .width(30)
              .margin({right:15})
              .fillColor('#2B2C2E')
            TextInput({ text: $$this.eventTitle, placeholder: '标题' })
              .placeholderColor(Color.Grey)
              .placeholderFont({ size: 23, weight: 400 })
              .caretColor(Color.Blue)
              .width('80%')
              .fontSize(23)
          }
        }

        // 地点输入
        ListItem() {
          Row() {
            Image($r('app.media.local_fill'))
              .width(30)
              .margin({right:15})
              .fillColor('#2B2C2E')
            TextInput({ text: $$this.eventLocation, placeholder: '地点' })
              .placeholderColor(Color.Grey)
              .placeholderFont({ size: 23, weight: 400 })
              .caretColor(Color.Blue)
              .width('80%')
              .fontSize(23)
          }
        }

        //开始时间栏（点击弹出时间选择器）
        ListItem() {
          Column()
          {
            Row()
            {
              Row({ space: 8 }) {
                Image($r('app.media.clock'))
                  .width(30)
                  .fillColor('#2B2C2E')
                Text('开始')
                  .margin({left:23})
                  .fontSize(23)
                  .fontColor('#2B2C2E')
              }
              Text(`${this.month}月${this.date}日 ${this.startHour.toString().padStart(2,'0')}:${this.startMinute.toString().padStart(2,'0')}`)
                .fontSize(18)
                .fontColor(Color.Grey)
            }
            .width('100%')
            .height(56)
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ right: 15 })
            .onClick(() => {
              this.isStart=true
              this.showTimePicker=!this.showTimePicker})

            Divider().strokeWidth(1).color('#DBDBDB').margin({left:60})

            Row()
            {
              Row({ space: 8 }) {
                Blank()
                  .width(15)
                Text('结束')
                  .margin({left:23})
                  .fontSize(23)
                  .fontColor('#2B2C2E')
              }
              Text(`${this.endHour.toString().padStart(2,'0')}:${this.endMinute.toString().padStart(2,'0')}`)
                .fontSize(18)
                .fontColor(Color.Grey)
            }
            .width('100%')
            .height(56)
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ left: 15, right: 15 })
            .onClick(() => {
              this.isStart=false
              this.showTimePicker=!this.showTimePicker})
          }
        }

      }
      .padding(15)
      .borderRadius(25)
      .backgroundColor(Color.White)
      .width('95%')
      .margin({left:20,right:20})
      .height('')

      //提醒表单
      if(this.showTimePicker===false)
      {
        List({space:20}) {
          //提醒
          ListItem() {
            Row() {
              Image($r('app.media.alarm_fill_1'))
                .width(30)
                .margin({right:15})
                .fillColor('#2B2C2E')
              Text('提醒')
                .margin({left:23})
                .fontSize(23)
                .fontColor('#2B2C2E')
                .layoutWeight(1)
              Image(this.reminder?$r('app.media.reminder'):$r('app.media.not_reminder'))
                .width(50)
                .margin({right:15})
                .fillColor('#2B2C2E')
                .onClick(()=>{this.reminder=!this.reminder})
            }
          }

          if(this.reminder)
          {
            // 全天提醒
            ListItem() {
              Row() {
                Image($r('app.media.exclamationmark'))
                  .width(30)
                  .margin({right:15})
                  .fillColor('#2B2C2E')
                  .scale({ x: 1.3, y: 1.3 })
                Text('全天提醒')
                  .margin({left:23})
                  .fontSize(23)
                  .fontColor('#2B2C2E')
                  .layoutWeight(1)
                Image(this.allDay?$r('app.media.reminder'):$r('app.media.not_reminder'))
                  .width(50)
                  .margin({right:15})
                  .fillColor('#2B2C2E')
                  .onClick(()=>{this.allDay=!this.allDay})
              }
            }

            // 提前分钟
            ListItem() {
              Row()
              {
                Image($r('app.media.bell_fill'))
                  .width(30)
                  .margin({right:15})
                  .fillColor('#2B2C2E')
                TextInput({ text: $$this.advanceMinutes, placeholder: '15' }) // 只显示数字
                  .placeholderColor(Color.Grey)
                  .placeholderFont({ size: 23, weight: 400 })
                  .caretColor(Color.Blue)
                  .width('60%')
                  .fontSize(23)
                  .type(InputType.Number)
                  .layoutWeight(1)
                  .onEditChange((isEditing: boolean) => {
                    if (!isEditing) {
                      let value = this.advanceMinutes?.toString().trim() ?? ''
                      let matched = value.match(/^[1-9]\d*$/)
                      if (matched) {
                        this.advanceMinutes = matched[0]
                      } else {
                        this.advanceMinutes=''
                      }
                    }
                  })

                Text('分钟前提醒') // 直接跟在输入框后面
                  .margin({left:10})
                  .fontSize(20)
                  .fontColor(Color.Grey)
              }
            }
          }
        }
        .divider({strokeWidth:1,color:'#DBDBDB',startMargin:65})
        .padding(15)
        .borderRadius(25)
        .backgroundColor(Color.White)
        .width('95%')
        .margin({top:20,left:20,right:20})
        .height('')
      }

      if(this.showTimePicker)
      {
        if(this.isStart)
        {
          this.showTimePickerLayout(this.startHour,this.startMinute)
        }
        else
       {
         this.showTimePickerLayout(this.endHour,this.endMinute)
       }
      }
    }
    .backgroundColor('#F2F3F7')
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
      const params = context.pathInfo.param as isUpdate

      if (params && params.isUpdate) {
        this.isUpdate = params.isUpdate
        this.event=params.event

        this.eventTitle=this.event.title
        this.eventLocation=this.event.location
        this.year=this.event.year
        this.month=this.event.month
        this.date=this.event.date
        this.startHour=this.event.startHour
        this.startMinute=this.event.startMinute
        this.endHour=this.event.endHour
        this.endMinute=this.event.endMinute
        this.reminder=this.event.reminder
        this.allDay=this.event.allDay
        this.advanceMinutes=this.event.advanceMinutes.toString()
      }
    })
  }
}
