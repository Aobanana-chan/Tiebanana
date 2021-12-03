import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

class ImgExplorer extends StatefulWidget {
  final String imgUrl;
  final String? highQualityUrl;
  ImgExplorer({Key? key, required this.imgUrl, this.highQualityUrl})
      : super(key: key);

  @override
  _ImgExplorerState createState() => _ImgExplorerState();
}

class _ImgExplorerState extends State<ImgExplorer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
                onPressed: () {
                  //TODO:保存图片
                  // getCachedImageFile(url)
                },
                icon: Icon(Icons.save))
          ],
          leading: IconButton(
            icon: Icon(Icons.arrow_back_sharp),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Stack(
          children: [
            Center(
              child: Hero(
                tag: widget.imgUrl,
                child: ExtendedImage.network(
                  widget.imgUrl,
                  mode: ExtendedImageMode.gesture,
                  cache: true,
                ),
              ),
            ),
            SizedBox.expand(
              child: Visibility(
                  visible: widget.highQualityUrl == null ? false : true,
                  child: FractionallySizedBox(
                      alignment: Alignment.bottomCenter,
                      heightFactor: 0.2,
                      child: Container(
                        child: FractionallySizedBox(
                          heightFactor: 0.3,
                          widthFactor: 0.5,
                          child: Container(
                            decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white,
                                  width: 0.3,
                                ),
                                borderRadius: BorderRadius.circular(10)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: MaterialButton(
                                onPressed: () {
                                  //TODO:查看原图
                                },
                                child: Text(
                                  "查看原图",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ))),
            )
          ],
        ),
      ),
    );
  }
}

class ZoomedImgExplorer extends StatefulWidget {
  final List<String> imgUrls;
  final List<String?>? highQualityUrls;
  final ExtendedPageController? pageController;
  final int index;
  ZoomedImgExplorer(
      {Key? key,
      required this.imgUrls,
      this.pageController,
      this.index = 0,
      this.highQualityUrls})
      : super(key: key);

  @override
  _ZoomedImgExplorerState createState() => _ZoomedImgExplorerState();
}

class _ZoomedImgExplorerState extends State<ZoomedImgExplorer> {
  late int currentIndex;
  late List<bool> highQualityLoaded;
  double? highQualityLoadState;
  late List<bool> wantShowScrImg;
  Future<void> highQualityCacheCheck() async {
    int i = 0;
    for (var url in widget.highQualityUrls ?? []) {
      //图片原图已缓存，直接加载原图
      if (highQualityLoaded[i] == false &&
          await getCachedImageFilePath(url) != null) {
        highQualityLoaded[i] = true;
      }
      i++;
    }
  }

  bool shouldShowOriginSrc() {
    if (widget.highQualityUrls?[currentIndex] == null) {
      return false;
    }
    if (highQualityLoaded[currentIndex] == true) {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    highQualityLoaded = List.filled(widget.imgUrls.length, false);
    wantShowScrImg = List.filled(widget.imgUrls.length, false);
  }

  @override
  void dispose() {
    clearGestureDetailsCache();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    currentIndex = widget.pageController?.initialPage ?? 0;
    return Container(
      color: Colors.black,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
                padding: EdgeInsets.all(3),
                onPressed: () {
                  //TODO:保存图片
                  // getCachedImageFile(url)
                },
                icon: Icon(Icons.save))
          ],
          leading: IconButton(
            icon: Icon(Icons.arrow_back_sharp),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Stack(
          children: [
            Container(
              padding: EdgeInsets.all(5),
              child: ExtendedImageGesturePageView.builder(
                itemBuilder: (itemBuilder, index) {
                  return Hero(
                      tag: widget.imgUrls[index],
                      child: ExtendedImage.network(
                        highQualityLoaded[index] == false
                            ? widget.imgUrls[index]
                            : widget.highQualityUrls![index]!,
                        mode: ExtendedImageMode.gesture,
                        initGestureConfigHandler: (state) {
                          return GestureConfig(
                              inPageView: true,
                              initialScale: 1.0,
                              cacheGesture: true);
                        },
                        loadStateChanged: (state) {
                          if (state.loadingProgress == null ||
                              state.loadingProgress!.expectedTotalBytes ==
                                  null) {
                            highQualityLoadState = null;
                          } else {
                            highQualityLoadState =
                                (state.loadingProgress!.cumulativeBytesLoaded /
                                    state.loadingProgress!.expectedTotalBytes!);
                          }
                          //未加载完前显示低质量图片
                          return ExtendedImage.network(
                            widget.imgUrls[index],
                            mode: ExtendedImageMode.gesture,
                            initGestureConfigHandler: (state) {
                              return GestureConfig(
                                  inPageView: true,
                                  initialScale: 1.0,
                                  cacheGesture: true);
                            },
                          );
                        },
                      ));
                },
                controller: widget.pageController,
                itemCount: widget.imgUrls.length,
                onPageChanged: (index) {
                  currentIndex = index;
                },
                physics: BouncingScrollPhysics(),
                pageSnapping: true,
              ),
            ),
            SizedBox.expand(
              child: Visibility(
                  visible: shouldShowOriginSrc(),
                  child: FractionallySizedBox(
                      alignment: Alignment.bottomCenter,
                      heightFactor: 0.2,
                      child: Container(
                        child: FractionallySizedBox(
                          heightFactor: 0.3,
                          widthFactor: 0.5,
                          child: Container(
                            decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white,
                                  width: 0.3,
                                ),
                                borderRadius: BorderRadius.circular(10)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: MaterialButton(
                                onPressed: () {
                                  //TODO:查看原图
                                  wantShowScrImg[currentIndex] = true;
                                },
                                child: Text(
                                  wantShowScrImg[currentIndex] == false
                                      ? "查看原图"
                                      : "加载中... $highQualityLoadState",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ))),
            )
          ],
        ),
      ),
    );
  }
}
