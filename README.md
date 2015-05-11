#Batched Handlers

Easily batch handlers while doing the work once and call all of them as if you were calling one.

## Usage

```
//Create a manager
self.manager = [BHManager new];

//––––––––––––––––––––––––––––––––––––––––––––––––––
//Later when a method with a handler is called...
//––––––––––––––––––––––––––––––––––––––––––––––––––
- (void)doAsyncWork:(void(^)(id result, NSError *error)handler
{
  //Any cache checking goes here...
  
  //The manager returns a block with the same interface as the passed block
  handler = BHManagerAddHandler(self.manager,handler,NSStringFromSelector(_cmd)); //We use the selector as a key
  //Continue only if a handler is returned 
  if (!handler) {
    return;
  }

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    //Do async work
    handler(result, error);
  });
}
```

In case you want to accept NULL handlers, you must register a sample block beforehand:

```
//Note this block is never executed nor does it need to do anything, 
//just be of the same interface as the passed handlers

[self.manager setSampleHandler:^(id r, NSError *e){}
              forKey:@NSStringFromSelector(@selector(doAsyncWork:))];
```

## Installation

BatchedHandlers is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "BatchedHandlers"
```