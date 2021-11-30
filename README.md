# ハンズオン資料

NCMBでは公式SDKとしてSwift/Objective-C/Java/Unity/JavaScript SDKを用意しています。また、それ以外にもコミュニティSDKとして、非公式ながらFlutter/React Native/Google Apps Script/C#/Ruby/Python/PHPなど幅広い言語向けにSDKが開発されています。

このハンズオンでは、コミュニティSDKの一つであるFlutter SDKを使ってTodoアプリを作ります。

## ベースのコード

今回のハンズオンで利用するベースアプリです。NCMB以外のUI周りのコードは実装済みです。


## lib/main.dartについて

今回のコードはすべて main.dart に記述しています。クラスは次の5つです。

- MyTodoApp
- TodoListPage
- _TodoListPageState
- TodoPage
- _TodoPageState

### MyTodoApp

一番ベースになるStatelessWidgetです。MaterialAppの定義、TodoListPageの呼び出しを行います。

### TodoListPage

StatefulWidgetです。_TodoListPageStateを呼び出しています。

### _TodoListPageState

![FireShot Capture 230 - タスクアプリ - localhost 20211117111623 - 230.jpg](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/197026/411f169e-cd15-50d8-497f-3e907b94c364.jpeg)

タスク一覧画面用です。NCMBにあるタスク一覧を取得して表示したり、タスクの追加や編集画面への遷移、タスクの削除を行います。

### TodoPage

StatefulWidgetです。_TodoPageStateを呼び出しています。

### _TodoPageState

タスクの作成と、既存タスクの編集を行います。

![FireShot Capture 230 - タスクアプリ - localhost 20211117111624 - 230.jpg](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/197026/ce532d12-0516-d308-8c18-720488dcbe97.jpeg)


## NCMB SDKのインストール（適用済み）

NCMB SDKは `flutter pub add ncmb` でインストールできます。

```
flutter pub add ncmb
```

記事執筆時点での最新版は `2.0.3` です。

## NCMB SDKの初期化

まず main.dart にてNCMB SDKをインポートします。

```dart
// 記述済み
import 'package:ncmb/ncmb.dart';
```

main関数にて初期化します。 `YOUR_APPLICATION_KEY` と `YOUR_CLIENT_KEY` はそれぞれ自分のものと置き換えてください。

```dart
// 記述してください。
void main() {
  // 1. NCMBを初期化
  NCMB('YOUR_APPLICATION_KEY', 'YOUR_CLIENT_KEY');
  // 最初に表示するWidget
  runApp(MyTodoApp());
}
```

これでNCMB SDKの利用準備が整います。

## タスク追加画面への遷移

タスクの追加は次のフローで処理を行います。

1. 一覧画面上にあるプラスアイコンをタップしてタスク追加画面に遷移
2. タスク名を入力して保存ボタンをタップ
3. タスクをNCMBのデータストアに保存
4. 一覧画面に戻る

### 一覧画面上にあるプラスアイコンをタップしてタスク追加画面に遷移

![FireShot Capture 230 - タスクアプリ - localhost 20211117111623 - 230のコピー.jpg](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/197026/faa212a3-91a0-7615-4d0c-1ab8d94f24d8.jpeg)

必要な部分だけを抜き出しますが、AppBarにあるプラスアイコンをタップした際に、TodoPageへ遷移します。その際、新規でNCMBObjectを渡しています。NCMBObjectはNCMBのデータストアに保存する際に利用するクラスです。引数で与えているTodoはクラス名で、DBでいうテーブル名相当になります。

```dart
// 記述済み
// タスク一覧画面用ステート
class _TodoListPageState extends State<TodoListPage> {
  // 省略
  // 画面構築
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 画面上部に表示するAppBar
      appBar: AppBar(
        title: Text('タスク一覧'),
        // タスク追加用のアイコンを設置
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              // 新しいTodoを取得
              final NCMBObject item = await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) {
                  // タスクの追加、編集を行う画面への遷移
                  return TodoPage(
                    // 初期値としてNCMBObjectを渡す
                    todo: NCMBObject('Todo'),
                  );
                }),
              );
              // 省略
            }
          )
        ]
      )
    )
  }
}
```

TodoPageでは `_TodoPageState` を呼び出しています。_TodoPageStateでは `widget.todo` にてNCMBObjectを利用できます。

```dart
// 記述済み
// Todoを受け取るステートフルウィジェット
class TodoPage extends StatefulWidget {
  TodoPage({
    Key key,
    this.todo,
  }) : super(key: key);

  final NCMBObject todo;

  @override
  _TodoPageState createState() => _TodoPageState();
}
```

### タスク名を入力して保存ボタンをタップ

![FireShot Capture 230 - タスクアプリ - localhost 20211117111624 - 230.jpg](https://qiita-image-store.s3.ap-northeast-1.amazonaws.com/0/197026/3ea3dc31-7a2b-b568-620a-a5eb64ee068a.jpeg)


`_TodoPageState` の内容です。NCMBObjectではgetメソッドを使ってデータを取得できます。この時、ユニークキーであるobjectIdがnullか否かによって、データの新規作成と更新とを判別できます。

TextFormFieldの初期値は `(_text = widget.todo.get('body') as String)` としています。NCMBObjectのbodyに入っている値（新規作成時はnull）をStringにキャストし、 `_text` に適用しています。 `_text` はタスクの入力値が変化した場合にも適用しています。

```dart
// 2. 保存処理の下に記述してください
// Todoの追加、または更新を行うウィジェット
class _TodoPageState extends State<TodoPage> {
  // テキスト入力用
  String _text;
  @override
  Widget build(BuildContext context) {
    // 画面表示用のラベル
    final label = widget.todo.get('objectId') != null ? 'リスト更新' : 'リスト追加';
    return Scaffold(
      // 画面上部に表示するAppBar
      appBar: AppBar(
        title: Text(label),
        actions: <Widget>[
          // 新規保存、更新用のボタン
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () async {
              // 2. 保存処理
              widget.todo.set('body', _text);
              await widget.todo.save();
              // 前の画面に戻る
              Navigator.of(context).pop(widget.todo);
            },
          ),
        ],
      ),
      body: Container(
        // 余白を付ける
        padding: EdgeInsets.all(64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 8),
            // テキスト入力
            TextFormField(
              initialValue: (_text = widget.todo.get('body') as String),
              onChanged: (String value) {
                _text = value;
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

## 一覧画面への反映

タスク追加画面で新しくタスクが作成された場合、NCMBObjectが返ってきます。それを一覧画面の `todoList` へ setState関数内で追加します。戻るボタンを押して画面を戻った場合には item が null になっているので注意してください。

```dart
// 記述済み
final NCMBObject item = await Navigator.of(context).push(
  MaterialPageRoute(builder: (context) {
    // タスクの追加、編集を行う画面への遷移
    return TodoPage(
      // 初期値としてNCMBObjectを渡す
      todo: NCMBObject('Todo'),
    );
  }),
);
// レスポンスがあれば、リストに追加
// キャンセルされた場合は null が来る
if (item != null) {
  setState(() {
    todoList.add(item);
  });
}
```

## タスクの取得

NCMBに保存されたタスクを取得する際にはNCMBQueryを利用します。これは `_TodoListPageState` の `initState` にて呼び出します。

```dart
// 記述済み
// タスク一覧画面用ステート
class _TodoListPageState extends State<TodoListPage> {
  // Todoリストのデータ（初期値は空）
  List<NCMBObject> todoList = [];

  // 初期データをセットアップする処理
  @override
  void initState() {
    super.initState();
    getAllTask();
  }
}
```

`getAllTask` ではデータの取得と、結果をtodoListへ適用する処理を行っています。

```dart
// 3. getAllTask関数を完成させてください
// NCMBから既存のTodoリストを取得する処理
void getAllTask() async {
  // Todoクラス（DBで言うテーブル相当）を検索するクエリーオブジェクト
  var query = NCMBQuery('Todo');
  // データを取得
  var items = await query.fetchAll();
  // データを適用
  setState(() {
    todoList = items;
  });
}
```

### タスクの一覧表示

todoListをListViewで一覧表示しますが、スワイプ処理で削除ラベルを表示するために `Dismissible` を使っています。

```dart
// 記述済み
ListView.builder(
  itemCount: todoList.length,
  itemBuilder: (context, index) {
    final item = todoList[index];
    // スワイプで削除する機能
    return Dismissible(
      key: Key(item.get('objectId') as String),
      child: Card(
        child: ListTile(
          title: Text(item.get('body') as String),
          onTap: () async {
            // 後述
          }
        ),
      ),
      direction: DismissDirection.endToStart,
      // スワイプした際に表示する削除ラベル
      background: new Container(
          padding: EdgeInsets.only(right: 20.0),
          color: Colors.red,
          child: new Align(
            alignment: Alignment.centerRight,
            child: new Text('削除',
                textAlign: TextAlign.right,
                style: new TextStyle(color: Colors.white)),
          )),
      // スワイプした際に処理
      onDismissed: (direction) {
        // 後述
      },
    );
  },
),
```

## タスクの編集処理

タスクを編集する際には、タスクの追加する時と同じくTodoPageを使います。新規作成時と同じくNCMBObjectを渡しますが、今回は一覧で利用している既存のNCMBObjectを渡すだけです。

また、更新された場合にはtodoListへの追加ではなく、既存データの上書きになります。

```dart
// 記述済み
final NCMBObject obj = await Navigator.of(context).push(
  MaterialPageRoute(builder: (context) {
    return TodoPage(
      todo: item,
    );
  }),
);
// 編集後のデータがあれば、リストを更新する
if (obj != null) {
  setState(() {
    todoList[index] = obj;
  });
}
```

## タスクの削除処理

タスクをスワイプしきった際には削除を行います。削除は該当するタスクのdeleteメソッドで削除できます。

```dart
onDismissed: (direction) {
    // スワイプされた要素をデータから削除する
    setState(() {
			// 4. タスクを削除する
      item.delete();
      todoList.removeAt(index);
    });
    // Snackbarを表示する
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('削除しました')));
  },
);
```

## まとめ

今回はNCMBの次の機能を体験してもらいました。

- データストア
	- 作成
	- 更新
	- 削除
	- 検索

この他、NCMBでは認証、ファイルストア、プッシュ通知、スクリプトなどの機能があります。ぜひ他の機能も組み合わせて、皆さんのアプリ開発に活かしてください。
