import {NativeModules, Image} from 'react-native';

const {RNCImageEditor} = NativeModules;

type ImageCropData = {
  offset: {|
    x: number,
    y: number,
  |},
  size: {|
    width: number,
    height: number,
  |},
  displaySize?: ?{|
    width: number,
    height: number,
  |},
  resizeMode?: ?$Enum<{
    contain: string,
    cover: string,
    stretch: string,
  }>,
};

class ImageEditor {
  
  static cropImage(uri: string, cropData: ImageCropData): Promise<string> {
    return RNCImageEditor.cropImage(uri, cropData);
  }

  static getSize(uri: string): Promise<string> {
    return new Promise((resolve, reject) => {
      Image.getSize(uri, (width, height) => resolve({ width, height }), reject);
  })
  }
}

export default ImageEditor;
