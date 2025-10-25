import { MonthView } from './MonthView';
import { WeekView } from './WeekView';
import { DayView } from './DayView';

@ComponentV2
export struct CalendarTabs {
  @Local currentIndex: number = 0;

  build() {
    Column() {
      Tabs({ barPosition: BarPosition.Start, index: this.currentIndex }) {
        TabContent() {
          MonthView()
            .width('100%')
            .height('100%')
        }
        .tabBar({
          text: '月'
        })

        TabContent() {
          WeekView()
            .width('100%')
            .height('100%')
        }
        .tabBar({ text: '周' })

        TabContent() {
          DayView()
            .width('100%')
            .height('100%')
        }
        .tabBar({ text: '日' })
      }
      .onChange((index: number) => {
        this.currentIndex = index;
      })
      .height('100%')
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }
}


