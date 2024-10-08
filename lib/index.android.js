import {NativeModules} from 'react-native';

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
  
  static hideSplashScreen(): Promise<string> {
    return RNCImageEditor.hideSplashScreen();
  }

  static getBase64(uri: string): Promise<string> {
    return RNCImageEditor.getBase64(uri);
  }

  static rotate(path: string, quality: number, rotation = 0, outputPath = null): Promise<string> {
    return RNCImageEditor.rotate(path, quality, rotation, outputPath);
  }

  static getSize(uri: string): Promise<string> {
    return RNCImageEditor.getSize(uri);
  }
}

export default ImageEditor;
