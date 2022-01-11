//
//  ContentView.swift
//  ViewAdjust
//
//  Created by PC on 11/01/22.
//

import SwiftUI

struct ContentView: View {
    
    //These are the initial dimension of the actual image
    @State var imageWidth:CGFloat = 0
    @State var imageHeight:CGFloat = 0
    @State var croppingMagnification:CGFloat = 1
    @State var croppingOffset = CGSize(width: 0, height: 0)

    
    var body: some View {
        ZStack {
            ZStack {
                Color.black.opacity(0.8)
                Image(uiImage: UIImage(named: "demo_image")!)
                        .resizable()
                        .scaledToFill()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .clipped()
                        .overlay(GeometryReader{geo -> AnyView in
                            DispatchQueue.main.async{
                                self.imageWidth = geo.size.width
                                self.imageHeight = geo.size.height
                            }
                            return AnyView(EmptyView())
                        })
                    ViewFinderView(imageWidth: self.$imageWidth, imageHeight: self.$imageHeight, finalOffset: $croppingOffset, finalMagnification: $croppingMagnification)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct ViewFinderView:View{
    
    @Binding var imageWidth:CGFloat
    @Binding var imageHeight:CGFloat
    
    @State var activeOffset:CGSize = CGSize(width: 0, height: 0)
    @Binding var finalOffset:CGSize
    
    @State var activeMagnification:CGFloat = 0.96
    @Binding var finalMagnification:CGFloat
        
    var surroundingColor = Color.black.opacity(0.45)
    
    var body: some View {
        ZStack{
            //These are the views for the surrounding rectangles
            Group{
                Rectangle()
//                    .foregroundColor(Color.red.opacity(0.3))
                    .foregroundColor(surroundingColor)
                    .frame(width: ((imageWidth-getDimension(w: imageWidth, h: imageHeight))/2) + activeOffset.width + (getDimension(w: imageWidth, h: imageHeight) * (1 - activeMagnification) / 2), height: imageHeight)
                    .offset(x: getSurroundingViewOffsets(horizontal: true, left_or_up: true), y: 0)
                Rectangle()
//                    .foregroundColor(Color.blue.opacity(0.3))
                    .foregroundColor(surroundingColor)
                    .frame(width: ((imageWidth-getDimension(w: imageWidth, h: imageHeight))/2) - activeOffset.width + (getDimension(w: imageWidth, h: imageHeight) * (1 - activeMagnification) / 2), height: imageHeight)
                    .offset(x: getSurroundingViewOffsets(horizontal: true, left_or_up: false), y: 0)
                Rectangle()
//                    .foregroundColor(Color.yellow.opacity(0.3))
                    .foregroundColor(surroundingColor)
                    .frame(width: getDimension(w: imageWidth, h: imageHeight) * activeMagnification, height: ((imageHeight-getDimension(w: imageWidth, h: imageHeight))/2) + activeOffset.height + (getDimension(w: imageWidth, h: imageHeight) * (1 - activeMagnification) / 2))
                    .offset(x: activeOffset.width, y: getSurroundingViewOffsets(horizontal: false, left_or_up: true))
                Rectangle()
//                    .foregroundColor(Color.green.opacity(0.3))
                    .foregroundColor(surroundingColor)
                    .frame(width: getDimension(w: imageWidth, h: imageHeight) * activeMagnification, height: ((imageHeight-getDimension(w: imageWidth, h: imageHeight))/2) - activeOffset.height + (getDimension(w: imageWidth, h: imageHeight) * (1 - activeMagnification) / 2))
                    .offset(x: activeOffset.width, y: getSurroundingViewOffsets(horizontal: false, left_or_up: false))
            }
            //This view creates a very translucent rectangle that overlies the picture we'll be uploading
            Rectangle()
                .frame(width: getDimension(w: imageWidth, h: imageHeight)*activeMagnification, height: getDimension(w: imageWidth, h: imageHeight)*activeMagnification)
                .foregroundColor(Color.white.opacity(0.05))
                .offset(x: activeOffset.width, y: activeOffset.height)
            
            //These views create the white grid
            //This view creates the outer square
            Rectangle()
                .stroke(lineWidth: 1)
                .frame(width: getDimension(w: imageWidth, h: imageHeight)*activeMagnification, height: getDimension(w: imageWidth, h: imageHeight)*activeMagnification)
                .foregroundColor(.white.opacity(0.6))
                .offset(x: activeOffset.width, y: activeOffset.height)
            
            //This view creates a thin rectangle in the center that is 1/3 the outer square's width
            Rectangle()
                .stroke(lineWidth: 1)
                .frame(width: getDimension(w: imageWidth, h: imageHeight)*activeMagnification/3, height: getDimension(w: imageWidth, h: imageHeight)*activeMagnification)
                .foregroundColor(.white.opacity(0.6))
                .offset(x: activeOffset.width, y: activeOffset.height)
            
            //This view creates a thin rectangle in the center that is 1/3 the outer square's height
            Rectangle()
                .stroke(lineWidth: 1)
                .frame(width: getDimension(w: imageWidth, h: imageHeight)*activeMagnification, height: getDimension(w: imageWidth, h: imageHeight)*activeMagnification/3)
                .foregroundColor(.white.opacity(0.6))
                .offset(x: activeOffset.width, y: activeOffset.height)
            
            //MARK: - Top Left Arrow
            //UL corner icon
            Image("arrow_top_left")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.black)
                .offset(x: activeOffset.width - (activeMagnification*getDimension(w: imageWidth, h: imageHeight)/2), y: activeOffset.height - (activeMagnification*getDimension(w: imageWidth, h: imageHeight)/2))
                .padding(25)
                .gesture(
                    DragGesture()
                        .onChanged{drag in
                            //First it calculates the additional magnification this drag is proposing
                            let calcMag = getMagnification(drag.translation)
                            print("calcMag: ", calcMag)
                            //It then multiplies it against the magnification that was already present in your crop
                            let workingMagnification:CGFloat = finalMagnification * calcMag
                            print("workingMagnification: ", workingMagnification)
                            //**********************************
                            //This set of logic is used for calculations that prevent scaling to cause offset to go outside the actual image
                            //First we check the size of the offsets
                            let workingOffsetSize = (getDimension(w: imageWidth, h: imageHeight) * finalMagnification)-(getDimension(w: imageWidth, h: imageHeight) * activeMagnification)
                            print("workingOffsetSize: ", workingOffsetSize)
                            
                            //Then we check the offset of the image barring the current "onChanged" we are currently experiencing by adding the proposed "workingOffsetSize" to the displayed "finalOffset"
                            let workingOffset = CGSize(width: finalOffset.width + workingOffsetSize/2, height: finalOffset.height + workingOffsetSize/2)
                            print("workingOffset: ", workingOffset)
                            
                            //From here we calculate half the height of the original image and half the width, so we can use them to calculate if further scaling will extend our cropping view off the bounds of the screen
                            let halfImageHeight = self.imageHeight/2
                            let halfImageWidth = self.imageWidth/2
                            print("halfImageHeight: ", halfImageHeight)
                            print("halfImageWidth: ", halfImageWidth)
                            
                            //This variable is equal to half of the view finding square, factoring in the magnification
                            let proposed_halfSquareSize = (getDimension(w: imageWidth, h: imageHeight)*activeMagnification)/2
                            //**********************************
                            print("proposed_halfSquareSize: ", proposed_halfSquareSize)
                            //Here we are setting up the upper and lower limits of the magnificatiomn
                            if workingMagnification <= 0.96 && workingMagnification >= 0.4{
                                //If we fall within the scaling limits, then we will check that scaling would not extend the viewfinder past the bounds of the actual image
                                if proposed_halfSquareSize - workingOffset.height > halfImageHeight || proposed_halfSquareSize - workingOffset.width > halfImageWidth{
                                    print("scaling would extend past image bounds")
                                } else {
                                    activeMagnification = workingMagnification
                                }
                            } else if workingMagnification > 0.96{
                                activeMagnification = 0.96
                            } else {
                                activeMagnification = 0.4
                            }
                            print("activeMagnification: ", activeMagnification)
                            //As you magnify, you technically need to modify offset as well, because magnification changes are not symmetric, meaning that you are modifying the magnfiication only be shifting the upper and left edges inwards, thus changing the center of the croppedingview, so the offset needs to move accordingly
                            let offsetSize = (getDimension(w: imageWidth, h: imageHeight) * finalMagnification)-(getDimension(w: imageWidth, h: imageHeight) * activeMagnification)
                            print("offsetSize: ", offsetSize)
                            self.activeOffset.width = finalOffset.width + offsetSize/2
                            self.activeOffset.height = finalOffset.height + offsetSize/2
                            print("***********************************************")
//                            print("current yOffset = \(workingOffset.height)")
//                            print("half image height = \(halfImageHeight)")
//                            print("proposed half-square size = \(proposed_halfSquareSize)")
                            
                        }
                        .onEnded{drag in
                            //At the end you need to set the "final" variables equal to the "active" variables.
                            //The difference between these variables is that active is what is displayed, while final is what is used for calculations.
                            withAnimation {
                                self.activeMagnification = 0.96
                                self.finalMagnification = activeMagnification
                                self.activeOffset = CGSize(width: 0, height: 0)
                                self.finalOffset = activeOffset
                            }
                        }
                )
            
            //MARK: - Top Right Arrow
            
            Image("arrow_top_right")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.black)
                .offset(x: activeOffset.width + (activeMagnification*getDimension(w: imageWidth, h: imageHeight)/2), y: activeOffset.height - (activeMagnification*getDimension(w: imageWidth, h: imageHeight)/2))
                .padding(25)
                .gesture(
                    DragGesture()
                        .onChanged{drag in
                            //First it calculates the additional magnification this drag is proposing
                            let calcMag = getMagnification(drag.translation)
                            print("calcMag: ", calcMag)
                            //It then multiplies it against the magnification that was already present in your crop
                            let workingMagnification:CGFloat = finalMagnification * calcMag
                            print("workingMagnification: ", workingMagnification)
                            //**********************************
                            //This set of logic is used for calculations that prevent scaling to cause offset to go outside the actual image
                            //First we check the size of the offsets
                            let workingOffsetSize = (getDimension(w: imageWidth, h: imageHeight) * finalMagnification)-(getDimension(w: imageWidth, h: imageHeight) * activeMagnification)
                            print("workingOffsetSize: ", workingOffsetSize)
                            
                            //Then we check the offset of the image barring the current "onChanged" we are currently experiencing by adding the proposed "workingOffsetSize" to the displayed "finalOffset"
                            let workingOffset = CGSize(width: finalOffset.width + workingOffsetSize/2, height: finalOffset.height + workingOffsetSize/2)
                            print("workingOffset: ", workingOffset)
                            
                            //From here we calculate half the height of the original image and half the width, so we can use them to calculate if further scaling will extend our cropping view off the bounds of the screen
                            let halfImageHeight = self.imageHeight/2
                            let halfImageWidth = self.imageWidth/2
                            print("halfImageHeight: ", halfImageHeight)
                            print("halfImageWidth: ", halfImageWidth)
                            
                            //This variable is equal to half of the view finding square, factoring in the magnification
                            let proposed_halfSquareSize = (getDimension(w: imageWidth, h: imageHeight)*activeMagnification)/2
                            //**********************************
                            print("proposed_halfSquareSize: ", proposed_halfSquareSize)
                            //Here we are setting up the upper and lower limits of the magnificatiomn
                            if workingMagnification <= 0.96 && workingMagnification >= 0.4{
                                //If we fall within the scaling limits, then we will check that scaling would not extend the viewfinder past the bounds of the actual image
                                if proposed_halfSquareSize - workingOffset.height > halfImageHeight || proposed_halfSquareSize - workingOffset.width > halfImageWidth{
                                    print("scaling would extend past image bounds")
                                } else {
                                    activeMagnification = workingMagnification
                                }
                            } else if workingMagnification > 0.96{
                                activeMagnification = 0.96
                            } else {
                                activeMagnification = 0.4
                            }
                            print("activeMagnification: ", activeMagnification)
                            //As you magnify, you technically need to modify offset as well, because magnification changes are not symmetric, meaning that you are modifying the magnfiication only be shifting the upper and left edges inwards, thus changing the center of the croppedingview, so the offset needs to move accordingly
                            let offsetSize = (getDimension(w: imageWidth, h: imageHeight) * finalMagnification)-(getDimension(w: imageWidth, h: imageHeight) * activeMagnification)
                            print("offsetSize: ", offsetSize)
                            self.activeOffset.width = finalOffset.width - offsetSize/2
                            self.activeOffset.height = finalOffset.height - offsetSize/2
                            print("***********************************************")
//                            print("current yOffset = \(workingOffset.height)")
//                            print("half image height = \(halfImageHeight)")
//                            print("proposed half-square size = \(proposed_halfSquareSize)")
                            
                        }
                        .onEnded{drag in
                            //At the end you need to set the "final" variables equal to the "active" variables.
                            //The difference between these variables is that active is what is displayed, while final is what is used for calculations.
                            withAnimation {
                                self.activeMagnification = 0.96
                                self.finalMagnification = activeMagnification
                                self.activeOffset = CGSize(width: 0, height: 0)
                                self.finalOffset = activeOffset
                            }
                        }
                )
            //MARK: - Bottom Right Arrow
            Image("arrow_bottom_right")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.black)
                .offset(x: activeOffset.width + (activeMagnification*getDimension(w: imageWidth, h: imageHeight)/2), y: activeOffset.height + (activeMagnification*getDimension(w: imageWidth, h: imageHeight)/2))
                .padding(25)
                .gesture(
                    DragGesture()
                        .onChanged{drag in
                            //First it calculates the additional magnification this drag is proposing
                            let calcMag = getMagnification(drag.translation)
                            print("calcMag: ", calcMag)
                            //It then multiplies it against the magnification that was already present in your crop
                            let workingMagnification:CGFloat = finalMagnification * calcMag
                            print("workingMagnification: ", workingMagnification)
                            //**********************************
                            //This set of logic is used for calculations that prevent scaling to cause offset to go outside the actual image
                            //First we check the size of the offsets
                            let workingOffsetSize = (getDimension(w: imageWidth, h: imageHeight) * finalMagnification)-(getDimension(w: imageWidth, h: imageHeight) * activeMagnification)
                            print("workingOffsetSize: ", workingOffsetSize)
                            
                            //Then we check the offset of the image barring the current "onChanged" we are currently experiencing by adding the proposed "workingOffsetSize" to the displayed "finalOffset"
                            let workingOffset = CGSize(width: finalOffset.width + workingOffsetSize/2, height: finalOffset.height + workingOffsetSize/2)
                            print("workingOffset: ", workingOffset)
                            
                            //From here we calculate half the height of the original image and half the width, so we can use them to calculate if further scaling will extend our cropping view off the bounds of the screen
                            let halfImageHeight = self.imageHeight/2
                            let halfImageWidth = self.imageWidth/2
                            print("halfImageHeight: ", halfImageHeight)
                            print("halfImageWidth: ", halfImageWidth)
                            
                            //This variable is equal to half of the view finding square, factoring in the magnification
                            let proposed_halfSquareSize = (getDimension(w: imageWidth, h: imageHeight)*activeMagnification)/2
                            //**********************************
                            print("proposed_halfSquareSize: ", proposed_halfSquareSize)
                            //Here we are setting up the upper and lower limits of the magnificatiomn
                            if workingMagnification <= 0.96 && workingMagnification >= 0.4{
                                //If we fall within the scaling limits, then we will check that scaling would not extend the viewfinder past the bounds of the actual image
                                if proposed_halfSquareSize - workingOffset.height > halfImageHeight || proposed_halfSquareSize - workingOffset.width > halfImageWidth{
                                    print("scaling would extend past image bounds")
                                } else {
                                    activeMagnification = workingMagnification
                                }
                            } else if workingMagnification > 0.96{
                                activeMagnification = 0.96
                            } else {
                                activeMagnification = 0.4
                            }
                            print("activeMagnification: ", activeMagnification)
                            //As you magnify, you technically need to modify offset as well, because magnification changes are not symmetric, meaning that you are modifying the magnfiication only be shifting the upper and left edges inwards, thus changing the center of the croppedingview, so the offset needs to move accordingly
                            let offsetSize = (getDimension(w: imageWidth, h: imageHeight) * finalMagnification)-(getDimension(w: imageWidth, h: imageHeight) * activeMagnification)
                            print("offsetSize: ", offsetSize)
                            self.activeOffset.width = finalOffset.width + offsetSize/2
                            self.activeOffset.height = finalOffset.height + offsetSize/2
                            print("***********************************************")
                            //                            print("current yOffset = \(workingOffset.height)")
                            //                            print("half image height = \(halfImageHeight)")
                            //                            print("proposed half-square size = \(proposed_halfSquareSize)")
                            
                        }
                        .onEnded{drag in
                            //At the end you need to set the "final" variables equal to the "active" variables.
                            //The difference between these variables is that active is what is displayed, while final is what is used for calculations.
                            withAnimation {
                                self.activeMagnification = 0.96
                                self.finalMagnification = activeMagnification
                                self.activeOffset = CGSize(width: 0, height: 0)
                                self.finalOffset = activeOffset
                            }
                        }
                )
            
            //MARK: - Bottom Left Arrow
            
            Image("arrow_bottom_left")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.black)
                .offset(x: activeOffset.width - (activeMagnification*getDimension(w: imageWidth, h: imageHeight)/2), y: activeOffset.height + (activeMagnification*getDimension(w: imageWidth, h: imageHeight)/2))
                .padding(25)
//                .gesture(
//                    DragGesture()
//                        .onChanged{drag in
//                            //First it calculates the additional magnification this drag is proposing
//                            let calcMag = getMagnification(drag.translation)
//
//                            //It then multiplies it against the magnification that was already present in your crop
//                            let workingMagnification:CGFloat = finalMagnification * calcMag
//
//                            //**********************************
//                            //This set of logic is used for calculations that prevent scaling to cause offset to go outside the actual image
//                            //First we check the size of the offsets
//                            let workingOffsetSize = (getDimension(w: imageWidth, h: imageHeight) * finalMagnification)-(getDimension(w: imageWidth, h: imageHeight) * activeMagnification)
//
//                            //Then we check the offset of the image barring the current "onChanged" we are currently experiencing by adding the proposed "workingOffsetSize" to the displayed "finalOffset"
//                            let workingOffset = CGSize(width: finalOffset.width + workingOffsetSize/2, height: finalOffset.height + workingOffsetSize/2)
//
//                            //From here we calculate half the height of the original image and half the width, so we can use them to calculate if further scaling will extend our cropping view off the bounds of the screen
//                            let halfImageHeight = self.imageHeight/2
//                            let halfImageWidth = self.imageWidth/2
//
//                            //This variable is equal to half of the view finding square, factoring in the magnification
//                            let proposed_halfSquareSize = (getDimension(w: imageWidth, h: imageHeight)*activeMagnification)/2
//                            //**********************************
//
//                            //Here we are setting up the upper and lower limits of the magnificatiomn
//                            if workingMagnification <= 1 && workingMagnification >= 0.4{
//                                //If we fall within the scaling limits, then we will check that scaling would not extend the viewfinder past the bounds of the actual image
//                                if proposed_halfSquareSize - workingOffset.height > halfImageHeight || proposed_halfSquareSize - workingOffset.width > halfImageWidth{
//                                    print("scaling would extend past image bounds")
//                                } else {
//                                    activeMagnification = workingMagnification
//                                }
//                            } else if workingMagnification > 1{
//                                activeMagnification = 1
//                            } else {
//                                activeMagnification = 0.4
//                            }
//
//                            //As you magnify, you technically need to modify offset as well, because magnification changes are not symmetric, meaning that you are modifying the magnfiication only be shifting the upper and left edges inwards, thus changing the center of the croppedingview, so the offset needs to move accordingly
//                            let offsetSize = (getDimension(w: imageWidth, h: imageHeight) * finalMagnification)-(getDimension(w: imageWidth, h: imageHeight) * activeMagnification)
//
//                            self.activeOffset.width = finalOffset.width + offsetSize/2
//                            self.activeOffset.height = finalOffset.height + offsetSize/2
//                            print("current yOffset = \(workingOffset.height)")
//                            print("half image height = \(halfImageHeight)")
//                            print("proposed half-square size = \(proposed_halfSquareSize)")
//                        }
//                        .onEnded{drag in
//
//                            //At the end you need to set the "final" variables equal to the "active" variables.
//                            //The difference between these variables is that active is what is displayed, while final is what is used for calculations.
//                            self.finalMagnification = activeMagnification
//                            self.finalOffset = activeOffset
//
//                        }
//                )
            
        }
    }
    
    //This function gets the offset for the surrounding views that obscure what has not been selected in the crop
    func getSurroundingViewOffsets(horizontal:Bool, left_or_up:Bool) -> CGFloat {
        let initialOffset:CGFloat = horizontal ? imageWidth : imageHeight
        let negVal:CGFloat = left_or_up ? -1 : 1
        let compensator = horizontal ? activeOffset.width : activeOffset.height
        
        return (((negVal * initialOffset) - (negVal * (initialOffset - getDimension(w: imageWidth, h: imageHeight))/2))/2) + (compensator/2) + (-negVal * (getDimension(w: imageWidth, h: imageHeight) * (1 - activeMagnification) / 4))
    }
    
    //This function determines the intended magnification you were going for. It does so by measuring the distance you dragged in both dimensions and comparing it against the longest edge of the image. The larger ratio is determined to be the magnification that you intended.
    func getMagnification(_ dragTranslation:CGSize) -> CGFloat {
        print("dragTranslation: ",dragTranslation)
        if (getDimension(w: imageWidth, h: imageHeight) - dragTranslation.width)/getDimension(w: imageWidth, h: imageHeight) < (getDimension(w: imageWidth, h: imageHeight) - dragTranslation.height)/getDimension(w: imageWidth, h: imageHeight) {
            print("width dragTranslation")
            return (getDimension(w: imageWidth, h: imageHeight) - dragTranslation.width)/getDimension(w: imageWidth, h: imageHeight)
        } else {
            print("height dragTranslation")
            return (getDimension(w: imageWidth, h: imageHeight) - dragTranslation.height)/getDimension(w: imageWidth, h: imageHeight)
        }
    }
    
    //This function just gets the larger of two values, when comparing two inputs. It is typically executed by submitting a width and height of a view to return the larger of the two
    func getDimension(w:CGFloat,h:CGFloat) -> CGFloat{
        if h > w {
            return w
        } else {
            return h
        }
    }
}
