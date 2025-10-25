import { AppStorageV2 } from '@kit.ArkUI'

@Entry
@ComponentV2
struct Index
{
  pathStack:NavPathStack = AppStorageV2.connect(NavPathStack, 'NAV_PATH_STACK', () => new NavPathStack())!
  build(){
    Navigation(this.pathStack){

    }.onAppear(()=>{
      this.pathStack.pushPathByName("View",null,false)
    })
    .hideNavBar(true)
  }
}
