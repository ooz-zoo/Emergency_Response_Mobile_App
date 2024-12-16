import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../images/models.dart';

class BoundingBox extends StatelessWidget {
  final List<dynamic> results;
  final int previewH;
  final int previewW;
  final double screenH;
  final double screenW;
  final String model;

  const BoundingBox(this.results, this.previewH, this.previewW, this.screenH,
      this.screenW, this.model,
      {super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> renderBoxes() {
      return results.map((re) {
        var xVal = re["rect"]["x"];
        var widVal = re["rect"]["w"];
        var yVal = re["rect"]["y"];
        var heightVal = re["rect"]["h"];
        dynamic scaleW, scaleH, x, y, w, h;

        if (screenH / screenW > previewH / previewW) {
          scaleW = screenH / previewH * previewW;
          scaleH = screenH;
          var difW = (scaleW - screenW) / scaleW;
          x = (xVal - difW / 2) * scaleW;
          w = widVal * scaleW;
          if (xVal < difW / 2) w -= (difW / 2 - xVal) * scaleW;
          y = yVal * scaleH;
          h = heightVal * scaleH;
        } else {
          scaleH = screenW / previewW * previewH;
          scaleW = screenW;
          var difH = (scaleH - screenH) / scaleH;
          x = xVal * scaleW;
          w = widVal * scaleW;
          y = (yVal - difH / 2) * scaleH;
          h = heightVal * scaleH;
          if (yVal < difH / 2) h -= (difH / 2 - yVal) * scaleH;
        }

        return Positioned(
          left: math.max(0, x),
          top: math.max(0, y),
          width: w,
          height: h,
          child: Container(
            padding: const EdgeInsets.only(top: 7.0, left: 7.0),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color.fromRGBO(61, 200, 212, .9),
                width: 3.0,
              ),
            ),
            child: Text(
              "${re["detectedClass"]} ${(re["confidenceInClass"] * 100).toStringAsFixed(0)}%",
              style: const TextStyle(
                color: Color.fromRGBO(120, 34, 149, 1.0),
                fontSize: 11.0,
              ),
            ),
          ),
        );
      }).toList();
    }

    List<Widget> renderStrings() {
      double offset = -10;
      return results.map((re) {
        offset = offset + 13;
        return Positioned(
          left: 10,
          top: offset,
          width: screenW,
          height: screenH,
          child: Text(
            "${re["label"]} ${(re["confidence"] * 100).toStringAsFixed(0)}%",
            style: const TextStyle(
              color: Color.fromRGBO(37, 213, 253, 1.0),
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList();
    }

    List<Widget> renderKeypoints() {
      var lists = <Widget>[];
      results.forEach((re) {
        var list = re["keypoints"].values.map<Widget>((k) {
          var x0 = k["x"];
          var y0 = k["y"];
          double scaleW, scaleH, x, y;

          if (screenH / screenW > previewH / previewW) {
            scaleW = screenH / previewH * previewW;
            scaleH = screenH;
            var difW = (scaleW - screenW) / scaleW;
            x = (x0 - difW / 2) * scaleW;
            y = y0 * scaleH;
          } else {
            scaleH = screenW / previewW * previewH;
            scaleW = screenW;
            var difH = (scaleH - screenH) / scaleH;
            x = x0 * scaleW;
            y = (y0 - difH / 2) * scaleH;
          }
          return Positioned(
            left: x - 6,
            top: y - 6,
            width: 100,
            height: 12,
            child: Text(
              "● ${k["part"]}",
              style: const TextStyle(
                color: Color.fromRGBO(37, 253, 55, 1.0),
                fontSize: 12.0,
              ),
            ),
          );
        }).toList();

        lists.addAll(list);
      });

      return lists;
    }

    return Stack(
      children: model == mobilenet
          ? renderStrings()
          : model == posenet
              ? renderKeypoints()
              : renderBoxes(),
    );
  }
}
