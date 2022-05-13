import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:photo_manager/photo_manager.dart';

class ImgExplorer extends StatefulWidget {
  final String heroTagSalt;
  final String imgUrl;
  final String? highQualityUrl;
  const ImgExplorer(
      {Key? key,
      required this.imgUrl,
      this.highQualityUrl,
      required this.heroTagSalt})
      : super(key: key);

  @override
  _ImgExplorerState createState() => _ImgExplorerState();
}

class _ImgExplorerState extends State<ImgExplorer> {
  bool shouldShowOriginSrc = false;
  bool highQualityLoaded = false;
  double? highQualityLoadState;
  Future<void> highQualityCacheCheck() async {
    bool shouldupdate = false;

    //图片原图已缓存，直接加载原图
    if (highQualityLoaded == false &&
        widget.highQualityUrl != null &&
        await getCachedImageFilePath(widget.highQualityUrl!) != null) {
      highQualityLoaded = true;
      shouldupdate = true;
    }

    if (shouldupdate) {
      setState(() {});
    }
  }

  String qualitySelect() {
    if (highQualityLoaded == false && shouldShowOriginSrc == false) {
      // print(widget.imgUrls[index]);
      return widget.imgUrl;
    } else if (widget.highQualityUrl != null) {
      // print(widget.highQualityUrls![index]!);
      return widget.highQualityUrl!;
    }
    return widget.imgUrl;
  }

  @override
  void initState() {
    super.initState();
    highQualityCacheCheck();
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ExtendedImageGestureState> gestureKey =
        GlobalKey<ExtendedImageGestureState>();
    return Container(
      color: Colors.black,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
                onPressed: () async {
                  PhotoManager.editor.saveImageWithPath(
                      (await getCachedImageFile(qualitySelect()))?.path ?? "",
                      title: DateTime.now().toString());
                },
                icon: const Icon(Icons.save))
          ],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_sharp),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Stack(
          children: [
            Center(
              child: Hero(
                tag: widget.imgUrl + widget.heroTagSalt,
                child: ExtendedImage.network(
                  qualitySelect(),
                  mode: ExtendedImageMode.gesture,
                  cache: true,
                  handleLoadingProgress: true,
                  loadStateChanged: (state) {
                    switch (state.extendedImageLoadState) {
                      case LoadState.completed:
                        highQualityCacheCheck();
                        return null;
                      case LoadState.loading:
                        if (state.loadingProgress == null ||
                            state.loadingProgress!.expectedTotalBytes == null) {
                          highQualityLoadState = null;
                        } else {
                          highQualityLoadState =
                              (state.loadingProgress!.cumulativeBytesLoaded /
                                  state.loadingProgress!.expectedTotalBytes!);
                        }
                        //未加载完前显示低质量图片
                        return ExtendedImage.network(
                          widget.imgUrl,
                          extendedImageGestureKey: gestureKey,
                          mode: ExtendedImageMode.gesture,
                          initGestureConfigHandler: (_) {
                            return GestureConfig(
                                inPageView: true,
                                initialScale: 1.0,
                                cacheGesture: true);
                          },
                          handleLoadingProgress: true,
                        );
                      case LoadState.failed:
                        shouldShowOriginSrc = false;
                        Fluttertoast.showToast(msg: "原图加载失败");
                        return ExtendedImage.network(
                          widget.imgUrl,
                          extendedImageGestureKey: gestureKey,
                          mode: ExtendedImageMode.gesture,
                          initGestureConfigHandler: (_) {
                            return GestureConfig(
                                inPageView: true,
                                initialScale: 1.0,
                                cacheGesture: true);
                          },
                          handleLoadingProgress: true,
                        );
                      default:
                    }
                    return null;
                  },
                ),
              ),
            ),
            SizedBox.expand(
              child: Visibility(
                  visible:
                      !shouldShowOriginSrc && widget.highQualityUrl != null,
                  child: FractionallySizedBox(
                      alignment: Alignment.bottomCenter,
                      heightFactor: 0.2,
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
                                shouldShowOriginSrc = true;
                                setState(() {
                                  highQualityCacheCheck();
                                });
                              },
                              child: Text(
                                shouldShowOriginSrc == false
                                    ? "查看原图"
                                    : "加载中... ${highQualityLoadState == null ? "" : "${(highQualityLoadState! * 100).toStringAsFixed(2)}%"}",
                                style: const TextStyle(color: Colors.white),
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
  final String heroTagSalt;
  const ZoomedImgExplorer(
      {Key? key,
      required this.imgUrls,
      this.pageController,
      this.index = 0,
      this.highQualityUrls,
      required this.heroTagSalt})
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
    bool shouldupdate = false;
    for (var url in widget.highQualityUrls ?? []) {
      //图片原图已缓存，直接加载原图
      if (highQualityLoaded[i] == false &&
          await getCachedImageFilePath(url) != null) {
        highQualityLoaded[i] = true;
        shouldupdate = true;
      }
      i++;
    }
    if (shouldupdate) {
      setState(() {});
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

  String qualitySelect(int index) {
    if (highQualityLoaded[index] == false && wantShowScrImg[index] == false) {
      // print(widget.imgUrls[index]);
      return widget.imgUrls[index];
    } else {
      // print(widget.highQualityUrls![index]!);
      return widget.highQualityUrls![index]!;
    }
  }

  @override
  void initState() {
    super.initState();
    highQualityLoaded = List.filled(widget.imgUrls.length, false);
    wantShowScrImg = List.filled(widget.imgUrls.length, false);
    highQualityCacheCheck();
    currentIndex = widget.pageController?.initialPage ?? 0;
  }

  @override
  void dispose() {
    clearGestureDetailsCache();
    super.dispose();
  }

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
                padding: const EdgeInsets.all(3),
                onPressed: () async {
                  //TODO:保存图片
                  PhotoManager.editor.saveImageWithPath(
                      (await getCachedImageFile(qualitySelect(currentIndex)))
                              ?.path ??
                          "",
                      title: DateTime.now().toString());
                },
                icon: const Icon(Icons.save))
          ],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_sharp),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text("${currentIndex + 1}/${widget.imgUrls.length}"),
        ),
        body: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              child: ExtendedImageGesturePageView.builder(
                canScrollPage: (gestureDetails) {
                  if (gestureDetails!.totalScale! > 1.0 &&
                      gestureDetails.layoutRect ==
                          gestureDetails.destinationRect) {
                    return false;
                  }
                  return true;
                },
                itemBuilder: (itemBuilder, index) {
                  final GlobalKey<ExtendedImageGestureState> gestureKey =
                      GlobalKey<ExtendedImageGestureState>();
                  return Hero(
                      tag: widget.imgUrls[index] + widget.heroTagSalt,
                      child: ExtendedImage.network(
                        qualitySelect(index),
                        extendedImageGestureKey: gestureKey,
                        mode: ExtendedImageMode.gesture,
                        initGestureConfigHandler: (state) {
                          return GestureConfig(
                            inPageView: true,
                            initialScale: 1.0,
                            cacheGesture: true,
                          );
                        },
                        handleLoadingProgress: true,
                        loadStateChanged: (state) {
                          // state.returnLoadStateChangedWidget = true;
                          switch (state.extendedImageLoadState) {
                            case LoadState.completed:
                              highQualityCacheCheck();
                              return null;
                            case LoadState.loading:
                              if (state.loadingProgress == null ||
                                  state.loadingProgress!.expectedTotalBytes ==
                                      null) {
                                highQualityLoadState = null;
                              } else {
                                highQualityLoadState = (state.loadingProgress!
                                        .cumulativeBytesLoaded /
                                    state.loadingProgress!.expectedTotalBytes!);
                              }
                              //未加载完前显示低质量图片
                              return ExtendedImage.network(
                                widget.imgUrls[index],
                                extendedImageGestureKey: gestureKey,
                                mode: ExtendedImageMode.gesture,
                                initGestureConfigHandler: (_) {
                                  return GestureConfig(
                                      inPageView: true,
                                      initialScale: 1.0,
                                      cacheGesture: true);
                                },
                                handleLoadingProgress: true,
                              );
                            case LoadState.failed:
                              wantShowScrImg[index] = false;
                              Fluttertoast.showToast(msg: "原图加载失败");
                              return ExtendedImage.network(
                                widget.imgUrls[index],
                                extendedImageGestureKey: gestureKey,
                                mode: ExtendedImageMode.gesture,
                                initGestureConfigHandler: (_) {
                                  return GestureConfig(
                                      inPageView: true,
                                      initialScale: 1.0,
                                      cacheGesture: true);
                                },
                                handleLoadingProgress: true,
                              );
                            default:
                          }
                          return null;
                        },
                      ));
                },
                controller: widget.pageController,
                itemCount: widget.imgUrls.length,
                onPageChanged: (index) {
                  currentIndex = index;
                  setState(() {});
                },
                physics: const BouncingScrollPhysics(),
                pageSnapping: true,
              ),
            ),
            SizedBox.expand(
              child: Visibility(
                  visible: shouldShowOriginSrc(),
                  child: FractionallySizedBox(
                      alignment: Alignment.bottomCenter,
                      heightFactor: 0.2,
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
                                wantShowScrImg[currentIndex] = true;
                                setState(() {
                                  highQualityCacheCheck();
                                });
                              },
                              child: Text(
                                wantShowScrImg[currentIndex] == false
                                    ? "查看原图"
                                    : "加载中... ${highQualityLoadState == null ? "" : "${(highQualityLoadState! * 100).toStringAsFixed(2)}%"}",
                                style: const TextStyle(color: Colors.white),
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
