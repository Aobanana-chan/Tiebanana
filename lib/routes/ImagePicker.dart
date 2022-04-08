import 'package:animate_do/animate_do.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flukit/flukit.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:math' as math;
import 'package:uuid/uuid.dart';

///图片选择和上传路由
class ImagePickerRoute extends StatefulWidget {
  const ImagePickerRoute({Key? key}) : super(key: key);

  @override
  State<ImagePickerRoute> createState() => _ImagePickerRouteState();
}

class _ImagePickerRouteState extends State<ImagePickerRoute>
    with SingleTickerProviderStateMixin {
  List<AssetPathEntity>? pathes;
  AssetPathEntity? pathSelected;
  List<DropdownMenuItem<AssetPathEntity>>? pathSelectItems;
  late AnimationController animationController;
  late Animation<double> animation;
  List<Future<File?>> imageFileList = [];
  List<AssetEntity> imageEntityList = [];
  bool _sendOriginImg = false;
  Set<AssetEntity> fileSelected = {};
  late Future<PermissionState> permission;
  @override
  void initState() {
    super.initState();
    permission = PhotoManager.requestPermissionExtend();
    animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    animation =
        CurvedAnimation(parent: animationController, curve: Curves.bounceOut);
    animation = Tween<double>(begin: 0, end: 2).animate(animation);
  }

  Future<void> addSelected(int index) async {
    fileSelected.add((await pathSelected?.assetList ?? [])[index]);
    setState(() {});
  }

  Future<void> removeSelected(int index) async {
    fileSelected.remove((await pathSelected?.assetList ?? [])[index]);
    setState(() {});
  }

  void tapSendOriginImg() {
    _sendOriginImg = !_sendOriginImg;
    setState(() {});
  }

  Future<void> initloadPhotos() async {
    //读取目录
    pathes = await PhotoManager.getAssetPathList(type: RequestType.image);
    //生成DropDown项目
    if (pathes != null) {
      pathSelectItems = pathes!
          .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
          .toList();
    }
    //设置默认dropDown值（缓存）
    try {
      if (pathSelected == null) {
        pathSelected = pathSelectItems?.first.value;
      } else {
        bool find = false;
        for (DropdownMenuItem<AssetPathEntity> item in pathSelectItems ?? []) {
          if (pathSelected?.id == item.value?.id) {
            pathSelected = item.value;
            find = true;
            break;
          }
        }
        if (!find) {
          pathSelected = pathSelectItems?.first.value;
        }
      }
      // ignore: empty_catches
    } catch (e) {}

    //读取图片
    imageEntityList = await loadImage();
    setState(() {});
  }

  Future<List<AssetEntity>> loadImage() async {
    imageFileList.clear();
    for (AssetEntity entity in (await pathSelected?.assetList) ?? []) {
      var file = entity.file;
      imageFileList.add(file);
    }
    return (await pathSelected?.assetList ?? []);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: permission,
      initialData: null,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        var body;
        if (snapshot.hasData) {
          if ((snapshot.data as PermissionState).isAuth) {
            if (pathes == null) {
              initloadPhotos();
            }
            body = GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, mainAxisSpacing: 5, crossAxisSpacing: 3),
              itemCount: imageFileList.length,
              itemBuilder: (BuildContext context, int index) {
                return KeepAliveWrapper(
                    child: LocalImageWidget(
                  index: index,
                  fileList: imageFileList,
                  addFunction: addSelected,
                  removeFunction: removeSelected,
                  entity: imageEntityList[index],
                  selectList: fileSelected.toList(),
                ));
              },
            );
          } else {
            body = const Center(
              child: Text("没有访问权限"),
            );
          }
        } else {
          body = Container();
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 1,
            title: Theme(
              data: Theme.of(context).copyWith(
                canvasColor: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AssetPathEntity>(
                  items: pathSelectItems,
                  onChanged: (value) {
                    if (pathSelected != value) {
                      fileSelected.clear();
                      pathSelected = value;
                      initloadPhotos();
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  value: pathSelected,
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  animationController.value = 0;
                  animationController.forward();
                  initloadPhotos();
                },
                icon: AnimatedBuilder(
                  animation: animation,
                  child: const Icon(Icons.refresh),
                  builder: (BuildContext context, Widget? child) {
                    return Transform.rotate(
                      angle: math.pi * animation.value,
                      child: child,
                    );
                  },
                ),
              ),
            ],
          ),
          body: body,
          bottomNavigationBar: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: LeftRightBox(
              verticalAlign: VerticalAlign.center,
              left: _OriginButton(
                onTap: tapSendOriginImg,
                selected: _sendOriginImg,
                text: "原图",
              ),
              right: GradientButton(
                  onPressed: () {
                    Navigator.pop(context, [fileSelected, _sendOriginImg]);
                  },
                  borderRadius: BorderRadius.circular(64),
                  child: const Text("提交")),
            ),
          ),
        );
      },
    );
  }
}

class LocalImageWidget extends StatefulWidget {
  final int index;
  final List<Future<File?>> fileList;
  final AssetEntity entity;
  final List<AssetEntity> selectList;
  final Future<void> Function(int index) addFunction;
  final Future<void> Function(int index) removeFunction;
  const LocalImageWidget(
      {Key? key,
      required this.index,
      required this.fileList,
      required this.addFunction,
      required this.removeFunction,
      required this.entity,
      required this.selectList})
      : super(key: key);

  @override
  State<LocalImageWidget> createState() => _LocalImageWidgetState();
}

class _LocalImageWidgetState extends State<LocalImageWidget> {
  bool selected = false;
  String heroTag = const Uuid().v4();

  void changeSelect({int? index}) {
    if (index != null) {
      if (selected) {
        widget.removeFunction(index);
      } else {
        widget.addFunction(index);
      }
    } else {
      if (selected) {
        widget.removeFunction(widget.index);
      } else {
        widget.addFunction(widget.index);
      }
    }
  }

  @override
  void didUpdateWidget(covariant LocalImageWidget oldWidget) {
    selected = false;
    for (var item in widget.selectList) {
      if (widget.entity == item) {
        selected = true;
        break;
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: FutureBuilder<File?>(
        future: widget.fileList[widget.index],
        initialData: null,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            var data = snapshot.data as File?;
            if (data != null) {
              return Hero(
                  tag: heroTag,
                  child: Stack(
                    children: [
                      SizedBox.expand(
                        child: FadeIn(
                            child: GestureDetector(
                          onTap: () async {
                            List<File> fileList = [];
                            for (var item in widget.fileList) {
                              var f = await item;
                              if (f != null) fileList.add(f);
                            }
                            var controller = ExtendedPageController(
                                initialPage: widget.index);
                            int? result =
                                await Navigator.push(context, MaterialPageRoute(
                              builder: (context) {
                                return ZoomedLocalImage(
                                  file: fileList,
                                  controller: controller,
                                  heroTag: heroTag,
                                  index: widget.index,
                                );
                              },
                            ));
                            if (result != null) {
                              changeSelect(index: result);
                            }
                          },
                          child: ExtendedImage.file(
                            data,
                            fit: BoxFit.cover,
                          ),
                        )),
                      ),
                      SizedBox.expand(
                        child: Container(
                          alignment: Alignment.topRight,
                          padding: const EdgeInsets.all(3),
                          child: GestureDetector(
                            onTap: () {
                              changeSelect();
                              setState(() {
                                selected = !selected;
                              });
                            },
                            child: selected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : const Icon(Icons.circle_outlined),
                          ),
                        ),
                      ),
                    ],
                  ));
            } else {
              return const Icon(
                Icons.close,
                color: Colors.red,
              );
            }
          } else {
            return Container(
              color: Colors.grey,
            );
          }
        },
      ),
    );
  }
}

class ZoomedLocalImage extends StatefulWidget {
  final List<File> file;
  final ExtendedPageController controller;
  final int index;
  final String heroTag;
  const ZoomedLocalImage(
      {Key? key,
      required this.file,
      required this.controller,
      required this.index,
      required this.heroTag})
      : super(key: key);

  @override
  State<ZoomedLocalImage> createState() => _ZoomedLocalImageState();
}

class _ZoomedLocalImageState extends State<ZoomedLocalImage> {
  late int currentIndex;

  @override
  void initState() {
    currentIndex = widget.controller.initialPage;
    super.initState();
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
                  Navigator.pop(context, currentIndex);
                },
                icon: const Icon(Icons.check))
          ],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_sharp),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Container(
          padding: const EdgeInsets.all(5),
          child: ExtendedImageGesturePageView.builder(
            canScrollPage: (gestureDetails) {
              if (gestureDetails!.totalScale! > 1.0 &&
                  gestureDetails.layoutRect == gestureDetails.destinationRect) {
                return false;
              }
              return true;
            },
            itemBuilder: (itemBuilder, index) {
              final GlobalKey<ExtendedImageGestureState> gestureKey =
                  GlobalKey<ExtendedImageGestureState>();
              return Hero(
                  tag: widget.heroTag,
                  child: ExtendedImage.file(
                    widget.file[index],
                    extendedImageGestureKey: gestureKey,
                    mode: ExtendedImageMode.gesture,
                    initGestureConfigHandler: (state) {
                      return GestureConfig(
                        inPageView: true,
                        initialScale: 1.0,
                        cacheGesture: true,
                      );
                    },
                  ));
            },
            controller: widget.controller,
            itemCount: widget.file.length,
            onPageChanged: (index) {
              currentIndex = index;
              setState(() {});
            },
            physics: const BouncingScrollPhysics(),
            pageSnapping: true,
          ),
        ),
      ),
    );
  }
}

class _OriginButton extends StatelessWidget {
  final bool selected;
  final void Function()? onTap;
  final String text;
  const _OriginButton(
      {Key? key, this.onTap, required this.selected, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected ? Icons.check_circle : Icons.circle_outlined,
            color: selected ? Colors.blue : Colors.black,
          ),
          Text(
            text,
            style: TextStyle(color: selected ? Colors.blue : Colors.black),
          )
        ],
      ),
    );
  }
}
