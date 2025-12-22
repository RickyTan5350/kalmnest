import 'package:markdown/markdown.dart' as md;

void main() {
  String markdown = '''
```php filename="contact.php"
<?php echo "Hello"; ?>
```

```js
// filename: script.js
console.log("Hi");
```
''';

  String html = md.markdownToHtml(
    markdown,
    extensionSet: md.ExtensionSet.gitHubFlavored,
  );

  print(html);
}
