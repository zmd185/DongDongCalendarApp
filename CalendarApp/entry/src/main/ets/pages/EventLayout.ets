import { AppStorageV2} from "@kit.ArkUI"
import CalendarEvent from "../model/Event"
import RdbUtils from "../services/EventStore"
import reminderService from "../services/ReminderService"

interface EventParams {
  event: CalendarEvent
}

@Builder
export function EventLayoutBuilder() {
  EventLayout()
}
@ComponentV2
struct EventLayout {
  pathStack: NavPathStack = AppStorageV2.connect(NavPathStack, 'NAV_PATH_STACK', () => new NavPathStack())!
  reminderService: reminderService = AppStorageV2.connect(reminderService, 'REMINDER_SERVICE', () => new reminderService())!

  @Local event:null|CalendarEvent=null;
  private weekdayLabels: string[] = ['日', '一', '二', '三', '四', '五', '六'];

  private deleteEvent(id:number)
  {
    RdbUtils.deleteById(id)
      .then(() => {
        this.reminderService.deleteReminder(id)
      }).catch((err:Error) => {
      console.log(err.message)
    })
  }

  build() {
    NavDestination() {
      Column()
      {
        Row()
        {
          Image($r("app.media.arrow_left"))
            .width(30)
            .margin(15)
            .fillColor('#2B2C2E')
            .onClick(() => {
              this.pathStack.replacePathByName("View",null,false)
            })
          Text("日程")
            .layoutWeight(1)
            .fontSize(30)
            .fontColor('#2B2C2E')
            .fontWeight(FontWeight.Bold)
        }
        Column()
        {
          Column({space:10})
          {
            Text(`${this.event?.title}`)
              .fontSize(25)
              .fontWeight(FontWeight.Medium)
            Text(`${this.event?.startHour.toString().padStart(2, '0')}:${this.event?.startMinute.toString().padStart(2, '0')} - ${this.event?.endHour.toString().padStart(2, '0')}:${this.event?.endMinute.toString().padStart(2, '0')}`)
              .fontSize(15)
            if (this.event)
            {
               Text(`${this.event.month}月${this.event.date}日星期${this.weekdayLabels[new Date(this.event.year, this.event.month - 1, this.event.date).getDay()]}`)
                 .fontSize(15)
            }
          }
          .margin({left:10,right:10})
          .alignItems(HorizontalAlign.Start)
          .padding(15)
          .borderRadius(25)
          .backgroundColor(Color.White)
          .width('95%')

          Row()
          {
            Image($r("app.media.calendar"))
              .width(30)
              .margin({right:10})
              .fillColor('#78787A')
            Text("·")
              .fontWeight(FontWeight.Bolder)
              .fontColor('#44A3E7')
              .fontSize(50)
              .margin({right:3})
            Text("我的日历")
              .fontSize(23)
          }
          .padding(15)
          .borderRadius(25)
          .backgroundColor(Color.White)
          .width('95%')
          .margin({left:10,right:10,bottom:20,top:20})

          Row()
          {
            Image($r("app.media.local_fill"))
              .width(30)
              .margin({right:10})
              .fillColor('#737373')
            Text(`${this.event?.location}`)
              .fontSize(23)
          }
          .padding(15)
          .borderRadius(25)
          .backgroundColor(Color.White)
          .width('95%')
          .margin({left:10,right:10})

          Row()
          {
            Image($r("app.media.alarm_fill_1"))
              .width(30)
              .margin({right:10})
              .fillColor('#737373')
            Text(`提醒`)
              .fontSize(23)
              .layoutWeight(1)
            Image(this.event?.reminder?$r('app.media.reminder'):$r('app.media.not_reminder'))
              .width(50)
              .margin({right:15})
              .fillColor('#2B2C2E')
          }
          .padding(15)
          .borderRadius(25)
          .backgroundColor(Color.White)
          .width('95%')
          .margin({left:10,right:10,top:20})

          Row()
          {
            Image($r("app.media.exclamationmark"))
              .width(30)
              .margin({right:10})
              .fillColor('#737373')
              .scale({ x: 1.3, y: 1.3 })
            Text(`全天提醒`)
              .fontSize(23)
              .layoutWeight(1)
            Image(this.event?.allDay?$r('app.media.reminder'):$r('app.media.not_reminder'))
              .width(50)
              .margin({right:15})
              .fillColor('#2B2C2E')
          }
          .padding(15)
          .borderRadius(25)
          .backgroundColor(Color.White)
          .width('95%')
          .margin({left:10,right:10,top:20})

          Row()
          {
            Image($r("app.media.bell_fill"))
              .width(30)
              .margin({right:10})
              .fillColor('#737373')
            Text(`提前${this.event?.advanceMinutes}分钟提醒`)
              .fontSize(23)
              .layoutWeight(1)
          }
          .padding(15)
          .borderRadius(25)
          .backgroundColor(Color.White)
          .width('95%')
          .margin({left:10,right:10,top:20})


        }
        .alignItems(HorizontalAlign.Start)



        Row()
        {
          Column()
          {
            Image($r("app.media.square_and_pencil"))
              .width(50)
              .margin({bottom:5})
            Text("编辑")
          }
          .onClick(()=>{
            this.pathStack.replacePathByName("EventEditor",{isUpdate:true,event:this.event},false)
          })
          .margin({left:95,right:95})
          Column()
          {
            Image($r("app.media.trash"))
              .width(50)
              .margin({bottom:5})
            Text("删除")
          }
          .onClick(()=>{
            if(this.event)
            {
              this.deleteEvent(this.event?.id)
              this.pathStack.replacePathByName("View",null,false)
            }
          })
        }
        .position({y:'90%'})
      }
      .width('95%')
      .alignItems(HorizontalAlign.Start)
    }
    .backgroundColor('#F2F3F7')
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack
      const params = context.pathInfo.param as EventParams

      if (params && params.event) {
        this.event = params.event
      }
    })
  }
}