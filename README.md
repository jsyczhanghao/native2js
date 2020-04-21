# native2js
flutter的一个jscore的插件, 支持console.log以及setTimeout

### 使用
```dart
import 'package:native2js/native2.js';

JsEngine engine = JsEngine();
await engine.evaluate('console.log(1)');
await engine.evaluate('''
  setTimeout(() => {console.log(2)}, 1000);
''');
```# native2js
