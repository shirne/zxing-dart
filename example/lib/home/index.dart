import 'package:flutter/cupertino.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<StatefulWidget> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('ZXing Demo'),
      ),
      backgroundColor: CupertinoColors.lightBackgroundGray,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: const [
              IconItem(
                image: 'aztec.png',
                title: 'Aztec',
                isAvailable: false,
              ),
              IconItem(
                image: 'code128.png',
                title: 'Oned',
                isAvailable: false,
              ),
              IconItem(
                image: 'datamatrix.png',
                title: 'DataMatrix',
                isAvailable: false,
              ),
              IconItem(
                image: 'pdf417.png',
                title: 'Pdf417',
                isAvailable: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IconItem extends StatelessWidget {
  final String image;
  final String title;
  final bool isAvailable;
  final void Function()? onTap;

  const IconItem({
    super.key,
    required this.image,
    required this.title,
    this.onTap,
    this.isAvailable = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Image.asset('assets/images/$image'),
              ),
            ),
            Text(
              title,
              style: CupertinoTheme.of(context).textTheme.actionTextStyle,
            ),
            if (!isAvailable)
              Text(
                'coming soon...',
                style: CupertinoTheme.of(context).textTheme.tabLabelTextStyle,
              )
            else
              const Text(' '),
          ],
        ),
      ),
    );
  }
}
