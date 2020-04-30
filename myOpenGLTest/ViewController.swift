//
//  ViewController.swift
//  myOpenGLTest
//
//  Created by sinyilin on 2020/4/28.
//  Copyright © 2020 sinyilin. All rights reserved.
//

import UIKit
import GLKit
import OpenGLES
import CoreGraphics
import CoreImage.CIFilter
import Photos
import LocalAuthentication

extension UIImage {
    func fixOrientation() -> UIImage
    {
        if self.imageOrientation == UIImage.Orientation.up {
            return self
        }
        
        var transform = CGAffineTransform.identity
        switch self.imageOrientation {
        case .down, .downMirrored:
            print("imageOrientation down")
            transform = transform.translatedBy(x: self.size.width, y: self.size.height)
            transform = transform.rotated(by: CGFloat(Double.pi));
        case .left, .leftMirrored:
            print("imageOrientation left")
            transform = transform.translatedBy(x: self.size.width, y: 0);
            transform = transform.rotated(by: CGFloat(Double.pi / 2));
        case .right, .rightMirrored:
            print("imageOrientation right")
            transform = transform.translatedBy(x: 0, y: self.size.height);
            transform = transform.rotated(by: CGFloat(-Double.pi / 2));
        case .up, .upMirrored:
            print("imageOrientation up")
            break
        }
        
        switch self.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: self.size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1);
        default:
            break;
        }
        
        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        let ctx = CGContext(
            data: nil,
            width: Int(self.size.width),
            height: Int(self.size.height),
            bitsPerComponent: self.cgImage!.bitsPerComponent,
            bytesPerRow: 0,
            space: self.cgImage!.colorSpace!,
            bitmapInfo: UInt32(self.cgImage!.bitmapInfo.rawValue)
        )
        
        ctx!.concatenate(transform);
        
        switch self.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            // Grr...
            ctx?.draw(self.cgImage!, in: CGRect(x:0 ,y: 0 ,width: self.size.height ,height:self.size.width))
        default:
            ctx?.draw(self.cgImage!, in: CGRect(x:0 ,y: 0 ,width: self.size.width ,height:self.size.height))
            break;
        }
        
        // And now we just create a new UIImage from the drawing context
        let cgimg = ctx!.makeImage()
        let img = UIImage(cgImage: cgimg!)
        
        return img;
    }
}
extension UIView {
    //将当前视图转为UIImage
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
class ViewController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate,ChangeHeadPicture {

    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var imgV: UIImageView!
    var filter:CIFilter!
    var imgVLongTap:UILongPressGestureRecognizer!
    var faceBox:UIView!
    var faceBoxImageView:UIImageView!
    var headPictureArray = ["head","head2","head3"]
    var hpa:HeadPictureAction!
    var headView:UIView!
    lazy var context: CIContext = {
        return CIContext (options:  nil )
    }()
    var faceIDcontext = LAContext()
    override func viewDidLoad() {
        super.viewDidLoad()
        imgV.layer.shadowOpacity = 0.8
        
        imgV.layer.shadowColor  = UIColor.black.cgColor
        
        imgV.layer.shadowOffset = CGSize(width: 1 , height: 1 )
        
        slider.maximumValue = 10
        
        slider.minimumValue = 0
        
        slider.value = 0
        
        slider.addTarget(self, action: #selector(sliderAction(sender:)), for: .valueChanged)
        
        let inputImage = CIImage(image: UIImage(named: "test")! )
        
        filter = CIFilter(name: "CIHueAdjust" )
        
        filter.setValue (inputImage, forKey:  kCIInputImageKey )
        
        imgVLongTap = UILongPressGestureRecognizer(target: self, action: #selector(imgVlongAction(tap:)))
        imgV.isUserInteractionEnabled = true
        imgV.addGestureRecognizer(imgVLongTap)
        hpa = HeadPictureAction()
        hpa.setDelegate(delegate: self)
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        checkFace()
    }
    @IBAction func filterBtn1(_ sender: UIButton) {
        filterSetImgV(name: "CISepiaTone")
    }
    @IBAction func filterBtn2(_ sender: UIButton) {
        filterSetImgV(name: "CIVignetteEffect")
    }
    @IBAction func filterBtn3(_ sender: UIButton) {

        let fileURL = Bundle.main.url(forResource: "test", withExtension: "png")
        // 2.创建CIImage对象
        let beginImage = imgV.image?.cgImage == nil ? CIImage(contentsOf: fileURL!):CIImage(cgImage: (imgV.image?.cgImage)!)
        oldPhoto(img: beginImage!, withAmount: 0.5)

    }
    @IBAction func openCamera(_ sender: UIButton) {
        if UIImagePickerController
            .isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .camera
            picker.allowsEditing = true // 可對照片作編輯
            self.present(picker, animated: true, completion: nil)
        } else {
            print("沒有相機鏡頭...") // 用alertView.show
        }
    }
    //MARK:自訂方法
    @objc func imgVlongAction(tap:UILongPressGestureRecognizer)
    {
        if tap.state == .began
        {
            showActionSheet(title: "你要幹嘛啦?", message: "點錯試試看")
        }
    }
    func showActionSheet(title:String,message:String?)
    {
        let alertc = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        let alertDownLoad = UIAlertAction(title: "下載圖片", style: .default) { (downloadAction) in
            self.showAlert(title: "儲存到相簿", message: nil, callback: {
                var myImage:UIImage?
                myImage = self.imgV.asImage()
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: myImage!)
                }, completionHandler: { (b, err) in
                    if b
                    {
                        self.showAlert(title: "已儲存到相簿", message: nil, callback: nil, cancelBool: false)
                    }
                    else
                    {
                        self.showAlert(title: "失敗", message: nil, callback: nil, cancelBool: false)
                    }
                })
            }, cancelBool: true)
        }
        let alertCancel = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        let alertChangeHead = UIAlertAction(title: "換顆頭", style: .default) { (changeHeadAction) in
            self.hpa.selectPicture()
        }
        alertc.addAction(alertChangeHead)
        alertc.addAction(alertDownLoad)
        alertc.addAction(alertCancel)
        self.present(alertc, animated: true, completion: nil)
    }
    func showAlert(title:String,message:String?,callback:(() -> ())?,cancelBool:Bool)
    {
        let alertc = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let alertCancel = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        let alertOK = UIAlertAction(title: "確定", style: .default) { (ok) in
            callback?()
        }
        alertc.addAction(alertOK)
        if cancelBool
        {
            alertc.addAction(alertCancel)
        }
        self.present(alertc, animated: true, completion: nil)
    }
    func oldPhoto(img: CIImage, withAmount intensity: Float) {
        let fileURL = Bundle.main.url(forResource: "test", withExtension: "png")
        // 2.创建CIImage对象
//        print("oldPhoto:\(imgV.image?.cgImage)")
        let beginImage = imgV.image?.cgImage == nil ? CIImage(contentsOf: fileURL!):CIImage(cgImage: (imgV.image?.cgImage)!)
        // 1 创建一个棕色滤镜
        let sepiaFilter = CIFilter(name: "CISepiaTone")
        sepiaFilter?.setValue(img, forKey: kCIInputImageKey)
        sepiaFilter?.setValue(intensity, forKey: kCIInputIntensityKey)
                        
        // 2 创建一个随机点滤镜
        let randomFilter = CIFilter(name: "CIRandomGenerator")
                        
        // 3
        let lighten = CIFilter(name: "CIColorControls")
        lighten?.setValue(randomFilter?.outputImage, forKey: kCIInputImageKey)
        lighten?.setValue(1 - intensity, forKey: "inputBrightness")
        lighten?.setValue(0, forKey: "inputSaturation")
                        
        // 4 将滤镜输出裁剪成原始图片大小
        let croppedImage = lighten?.outputImage?.cropped(to: beginImage!.extent)
                        
        // 5
        let composite = CIFilter(name: "CIHardLightBlendMode")
        composite?.setValue(sepiaFilter?.outputImage, forKey: kCIInputImageKey)
        composite?.setValue(croppedImage, forKey: kCIInputBackgroundImageKey)
                        
        // 6
        let vignette = CIFilter(name: "CIVignette")
        vignette?.setValue(composite?.outputImage, forKey: kCIInputImageKey)
        vignette?.setValue(intensity * 2, forKey: "inputIntensity")
        vignette?.setValue(intensity * 30, forKey: "inputRadius")
                        
        // 7
        let cgImage = context.createCGImage(vignette!.outputImage!, from: vignette!.outputImage!.extent)
        imgV.image = UIImage(cgImage: cgImage!)
    }
    @objc func sliderAction(sender:UISlider)
    {
//        print("senser value:\(sender.value)")
        self.filter.setValue(sender.value , forKey:kCIInputAngleKey )
        let outputImage =  self.filter.outputImage
        let cgImage = self.context.createCGImage(outputImage!, from: outputImage!.extent)
        DispatchQueue.main.async {
            self.imgV.image =  UIImage(cgImage:cgImage!)
        }
    }
    func filterSetImgV(name:String)
    {
        // 1.获取本地图片路径
        let fileURL = Bundle.main.url(forResource: "test", withExtension: "png")
        // 2.创建CIImage对象
//        print("cg:\(imgV.image?.cgImage),name:\(name)")
        let beginImage = imgV.image?.cgImage == nil ? CIImage(contentsOf: fileURL!):CIImage(cgImage: (imgV.image?.cgImage)!)
        // 3. 创建滤镜
        // 创建一个滤镜
        let filter = CIFilter(name: name)!
        filter.setValue(beginImage, forKey: kCIInputImageKey)
        // 设置输入的强度系数
        filter.setValue(0.5, forKey: kCIInputIntensityKey)
        // 4.将CIImage转换为UIImage
        //其实在这个API内部用到了CIContext，而它就是在每次使用的使用去创建一个新的CIContext，比较影响性能
        let newImage = UIImage(ciImage: filter.outputImage!)
        self.imgV.image = newImage
    }
    //FaceID
    func checkFace()
    {
        faceIDcontext.localizedCancelTitle = "Cancel"
        // 宣告一個變數接收 canEvaluatePolicy 返回的錯誤
        var error: NSError?
        // 評估是否可以針對給定方案進行身份驗證
        if faceIDcontext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            // 描述使用身份辨識的原因
            let reason = "Log in to your account"
            // 評估指定方案
            faceIDcontext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { (success, error) in
                if success {
                    DispatchQueue.main.async { [unowned self] in
                        self.showAlert(title: "Login Successful", message: error?.localizedDescription, callback: nil, cancelBool: false)
                    }
                } else {
                    DispatchQueue.main.async { [unowned self] in
                        self.showAlert(title: "Login Failed", message: error?.localizedDescription, callback: nil, cancelBool: false)
                    }
                }
            }
        } else {
            self.showAlert(title: "Failed", message: error?.localizedDescription, callback: nil, cancelBool: false)
        }
    }
    //按鈕設定
    func btnSetInit(btn:UIButton,tag:Int,imgStr:String,selector:Selector)
    {
        btn.backgroundColor = .white
        btn.tag = tag
        btn.setImage(UIImage(named: imgStr), for: .normal)
        btn.layer.cornerRadius = btn.frame.size.height * 0.5
        btn.layer.masksToBounds = true
        btn.layer.borderColor = UIColor.black.cgColor
        btn.layer.borderWidth = 1
        btn.addTarget(self, action: selector, for: .touchUpInside)
    }
    //換臉按鈕方法
    @objc func changeHeadBtnAction(sender:UIButton)
    {
        switch sender.tag
        {
        case 1:
            self.detect(img: "head")
            break
        case 2:
            self.detect(img: "head2")
            break
        case 3:
            self.detect(img: "head3")
            break
        default:
            break
        }
        headView.removeFromSuperview()
    }
    //人臉辨識
    func detect(img:String) {
        
        guard let personciImage = CIImage(image: imgV.image!) else {
            return
        }
        
        let accuracy = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: accuracy)
        let faces = faceDetector!.features(in: personciImage)
        
        // For converting the Core Image Coordinates to UIView Coordinates
        let ciImageSize = personciImage.extent.size

        var transform = CGAffineTransform(scaleX: 1, y: -1)
        transform = transform.translatedBy(x: 0, y: -ciImageSize.height)
        
        for face in faces as! [CIFaceFeature] {
            
            print("Found bounds are \(face.bounds)")
            
            // Apply the transform to convert the coordinates
            var faceViewBounds = face.bounds.applying(transform)
            
            // Calculate the actual position and size of the rectangle in the image view
            let viewSize = imgV.bounds.size
            let scale = min(viewSize.width / ciImageSize.width,
                            viewSize.height / ciImageSize.height)
            let offsetX = (viewSize.width - ciImageSize.width * scale) / 2
            let offsetY = (viewSize.height - ciImageSize.height * scale) / 2
            
            faceViewBounds = faceViewBounds.applying(CGAffineTransform(scaleX: scale, y: scale))
            print("y:\(faceViewBounds.origin.y),offsetY:\(offsetY)")
            faceViewBounds.origin.x += offsetX
            faceViewBounds.origin.y += offsetY
//            faceViewBounds.origin.y = abs(faceViewBounds.origin.y)

            if faceBox != nil
            {
                faceBox.removeFromSuperview()
            }
            faceBox = UIView(frame: faceViewBounds)
            faceBoxImageView = UIImageView(frame: faceBox.bounds)
            faceBoxImageView.image = UIImage(named: img)
            faceBoxImageView.contentMode = .scaleToFill
//            faceBox.layer.borderWidth = 3
//            faceBox.layer.borderColor = UIColor.red.cgColor
            faceBox.backgroundColor = UIColor.clear
            faceBox.addSubview(faceBoxImageView)
            
            imgV.addSubview(faceBox)
            print("faceBox:\(faceBox.frame)")
            
            if face.hasSmile {
                print("face is smiling");
            }
            if face.hasMouthPosition{
                print("mouth bounds are \(face.mouthPosition)")
            }
            if face.hasLeftEyePosition {
                print("Left eye bounds are \(face.leftEyePosition)")
            }
            if face.hasRightEyePosition {
                print("Right eye bounds are \(face.rightEyePosition)")
            }
            
        }
    }
    @IBAction func pickPhotoAction(_ sender: UIButton) {
//        print("pickPhotoAction")
        let photoController = UIImagePickerController()
        photoController.delegate = self
        photoController.sourceType = .photoLibrary
        present(photoController, animated: true, completion: nil)
    }
    //MARK:ImagePickerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if faceBox != nil{
            faceBox.removeFromSuperview()
        }
        let image = info[.originalImage] as? UIImage
        imgV.image = image?.fixOrientation()
        filter = CIFilter(name: "CIHueAdjust" )
        let inputImage = CIImage(cgImage: (imgV.image?.cgImage)!)
        filter.setValue (inputImage, forKey:  kCIInputImageKey )
        dismiss(animated: true, completion: nil)
    }
    //MARK:ChangeHeadPicture delegat
    func changeHeadAction() {
        if headView != nil
        {
            headView.removeFromSuperview()
        }
        headView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        headView.center.y = self.view.center.y
        headView.center.x = self.view.frame.size.width - (self.view.frame.size.height * 0.1)
        self.view.addSubview(headView)
        let btn1 = UIButton(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.height * 0.1, height: self.view.frame.size.width * 0.3))
        btn1.backgroundColor = .black
        let btn2 = UIButton(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.height * 0.1, height: self.view.frame.size.width * 0.3))
        let btn3 = UIButton(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.height * 0.1, height: self.view.frame.size.width * 0.3))
        btn3.backgroundColor = .black
        self.headView.addSubview(btn1)
        self.headView.addSubview(btn2)
        self.headView.addSubview(btn3)
        UIView.animate(withDuration: 0.5) {
            self.headView.frame.size.width = self.view.frame.size.width * 0.3
            self.headView.frame.size.height = self.view.frame.size.height * 0.3
            UIView.animate(withDuration: 0.5){
                btn1.frame.size.height = self.view.frame.size.height * 0.1
                btn2.frame.origin.y = self.view.frame.size.height * 0.1
                btn2.frame.size.height = self.view.frame.size.height * 0.1
                btn3.frame.origin.y = self.view.frame.size.height * 0.2
                btn3.frame.size.height = self.view.frame.size.height * 0.1
                self.btnSetInit(btn: btn1, tag: 1, imgStr: "head", selector: #selector(self.changeHeadBtnAction(sender:)))
                self.btnSetInit(btn: btn2, tag: 2, imgStr: "head2", selector: #selector(self.changeHeadBtnAction(sender:)))
                self.btnSetInit(btn: btn3, tag: 3, imgStr: "head3", selector: #selector(self.changeHeadBtnAction(sender:)))
            }
        }
    }
    
}

