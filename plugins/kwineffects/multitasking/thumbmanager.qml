import QtQuick 2.0
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.2 
import QtQuick.Window 2.0
import com.deepin.kwin 1.0
import QtGraphicalEffects 1.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kwin 2.0 as KWin

Rectangle {
    id: root
	width: Screen.width;
	height: Screen.height;
    color: "transparent"

    Rectangle {
        id: background
        x: 0
        y: 0
        height: root.height
        width: {
            var allWitdh = 0;
            for (var i = 0; i < $Model.numScreens(); ++i) {
                var geom = $Model.screenGeometry(i);
                allWitdh += geom.width;
            }
            return allWitdh;
        }
        color: "black"
        opacity: 0.6
    }

    function log(msg) {
        manager.debugLog(msg)
    }

    signal qmlRequestMove2Desktop(int screen, int desktop, var winId);
    signal resetModel();

	Component {
		id: windowThumbnailView;
		Rectangle {
			color: "red";
			Grid {
				Repeater {
                    id: windowThumbnailRepeater
					model: $Model.windows(screen, desktop);
					PlasmaCore.WindowThumbnail {
						width: thumbnailWidth;
						height: thumbnailHeight;
						winId: modelData;
                        
                        //zhd add 
                        id:winAvatar  
                        property var draggingdata: winId
                        property int dragingIndex:index
                        Drag.keys: ["DraggingWindowAvatar"];  //for holdhand
                        Drag.active:  avatarMousearea.drag.active 
                        Drag.hotSpot {
                            x: width/2
                            y: height/2
                        }
						MouseArea{ //zhd add   for drag window
                            id:avatarMousearea
							anchors.fill:parent
							drag.target:winAvatar
							drag.smoothed :true
                            
							onPressed: {
                                 winAvatar.Drag.hotSpot.x = mouse.x;
                                 winAvatar.Drag.hotSpot.y = mouse.y;
                            }
                            drag.onActiveChanged: {
                                if (!avatarMousearea.drag.active) {
                                    console.log('------- release on ' + avatarMousearea.drag.target)
                                    winAvatar.Drag.drop();
                                }
                            }
                            states: State {
                                when: avatarMousearea.drag.active;
                                ParentChange {
                                    target: winAvatar;
                                    parent: root;
                                }

                                PropertyChanges {
                                    target: winAvatar;
                                    z: 100;
                                    
                                }
                                // AnchorChanges {
                                //     target: winAvatar;
                                //     anchors.horizontalCenter: undefined
                                //     anchors.verticalCenter: undefined
                                // }
                            }
						}
                        //zhd add end 
					}
				}
                Connections {
                    target: root
                    onResetModel: {
                        windowThumbnailRepeater.model = $Model.windows(screen, desktop)
                        windowThumbnailRepeater.update()

                        console.log(" model is changed !!!!!!!!!!")
                    }
                }
			}
      	}
	}

	Component {
        id: desktopThumbmailView;
        Rectangle {
            width: screenWidth; 
            height: parent.height;
            color: "transparent"
            ListView {
                id: view
                width: 0;
                height: parent.height;
                orientation: ListView.Horizontal;
                model: $Model
                interactive : false;
                clip: true;

                


                delegate: Rectangle {
                    id: thumbDelegate;
                    width: manager.thumbSize.width;
                    height: manager.thumbSize.height;
                    color: "transparent"
                    
					DesktopThumbnail {
						id: desktopThumbnail;
						desktop: index + 1; 
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter

                        property var originParent: view
                        

                        width: thumbDelegate.width
                        height: thumbDelegate.height
                        MouseArea {
                            id: desktopThumbMouseArea
                            anchors.fill: parent;
                            hoverEnabled: true;

							onClicked: {
								$Model.setCurrentIndex(index);
							}

                            drag.target: desktopThumbnail;
                            onReleased: {
                                if (manager.desktopCount == 1) {
                                    return
                                }
                            }
                            onPressed: {
                                desktopThumbnail.Drag.hotSpot.x = mouse.x;
                                desktopThumbnail.Drag.hotSpot.y = mouse.y;
                            }
                            drag.onActiveChanged: {
                                if (!desktopThumbMouseArea.drag.active) {
                                    log('------- release ws on ' + thumbDelegate.Drag.target)
                                    desktopThumbnail.Drag.drop();
                                }
                            }

                            onEntered: {
                                if ($Model.rowCount() != 1) {
                                    closeBtn.visible = true;
                                }
                            }

                            onExited: {
                                closeBtn.visible = false;
                            }
                        }
                        property bool pendingDragRemove: false
                        Drag.keys: ["workspaceThumb"];
                        Drag.active: manager.desktopCount > 1 && desktopThumbMouseArea.drag.active 
                        Drag.hotSpot {
                            x: width/2
                            y: height/2
                        }
                    
                        states: State {
                            when: desktopThumbnail.Drag.active;
                            ParentChange {
                                target: desktopThumbnail;
                                parent: root;
                            }

                            PropertyChanges {
                                target: desktopThumbnail;
                                z: 100;
                            }
                            AnchorChanges {
                                target: desktopThumbnail;
                                anchors.horizontalCenter: undefined
                                anchors.verticalCenter: undefined
                            }
                        }

						//window thumbnail
						Loader {
                            id: winThumLoader
							sourceComponent: windowThumbnailView	
							property int thumbnailWidth: 50;
							property int thumbnailHeight: 50;
							property int screen: currentScreen; 
							property int desktop: desktopThumbnail.desktop;
						}

	                    Rectangle {
							id: closeBtn;
							anchors.right: parent.right;
							width: closeBtnIcon.width;
							height: closeBtnIcon.height;
							color: "transparent";
							property int desktop: desktopThumbnail.desktop;
                            visible: false;

							Image {
								id: closeBtnIcon;
								source: "qrc:///icons/data/close_normal.svg"
							}

							MouseArea {
								anchors.fill: closeBtn;
								onClicked: {
									$Model.remove(index);
								}
							}

							Connections {
								target: view;
								onCountChanged: {
									closeBtn.visible = false;
								}
							}
						}
					}

                    DropArea {
                        id: workspaceThumbDrop
                        anchors.fill: parent;
                        property int designated: index + 1;
                        property var originParent: view

                        z: 1
                        keys: ['workspaceThumb','DraggingWindowAvatar']  //  zhd change for drop a window
                       

                        onDropped: {
                            /* NOTE:
                            * during dropping, PropertyChanges is still in effect, which means 
                            * drop.source.parent should not be Loader
                            * and drop.source.z == 100
                            */
                            log("----------- workspaceThumb onDrop")

                            if (drop.keys[0] === 'workspaceThumb') {
                                var from = drop.source.desktop
                                var to = workspaceThumbDrop.designated
                                if (workspaceThumbDrop.designated == drop.source.desktop && drop.source.pendingDragRemove) {
                                        //FIXME: could be a delete operation but need more calculation
                                        log("----------- workspaceThumbDrop: close desktop " + from)
                                        $Model.remove(index);
                                } else {
                                    if (from == to) return
                                    if(drop.source.originParent != originParent) return
                                    log("from:"+from + " to:"+to)
                                    $Model.move(from-1, to-1);
                                    $Model.refreshWindows();
                                    resetModel()
                                    log("----------- workspaceThumbDrop: reorder desktop ")
                                }
                            }
                            if(drop.keys[0]==="DraggingWindowAvatar"){  //zhd add 

                                //console.log("DraggingWindowAvatar :Droppsource   " +drag.source.draggingdata +"desktop index:" + desktopThumbnail.desktop + "current screen: "+ currentScreen);
                                qmlRequestMove2Desktop(currentScreen,desktopThumbnail.desktop,drag.source.draggingdata);
                            }
                        }

                        onEntered: {
                            if (drag.keys[0] === 'workspaceThumb') {
                                log('------[workspaceThumbDrop]: Enter ' + workspaceThumbDrop.designated + ' from ' + drag.source
                                    + ', keys: ' + drag.keys + ', accept: ' + drag.accepted)
                            }
                        }

                        onExited: {
                            console.log("----------- workspaceThumb onExited")
                            if (drag.source.pendingDragRemove) {
                                hint.visible = false
                                drag.source.pendingDragRemove = hint.visible
                            }

                        }

                        onPositionChanged: {
                            if (drag.keys[0] === 'workspaceThumb') {
                                var diff = workspaceThumbDrop.parent.y - drag.source.y
                       //         log('------ ' + workspaceThumbDrop.parent.y + ',' + drag.source.y + ', ' + diff + ', ' + drag.source.height/2)
                                if (diff > 0 && diff > drag.source.height/2) {
                                    hint.visible = true
                                } else {
                                    hint.visible = false
                                }
                                drag.source.pendingDragRemove = hint.visible
                            }
                        }

                        Rectangle {
                            id: hint
                            visible: false
                            anchors.fill: parent
                            color: "transparent"

                            Text {
                                text: qsTr("Drag upwards to remove")
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: parent.height * 0.572

                                font.family: "Helvetica"
                                font.pointSize: 14
                                color: Qt.rgba(1, 1, 1, 0.5)
                            }

                            Canvas {
                                anchors.fill: parent
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.lineWidth = 0.5;
                                    ctx.strokeStyle = "rgba(255, 255, 255, 0.6)";

                                    var POSITION_PERCENT = 0.449;
                                    var LINE_START = 0.060;

                                    ctx.beginPath();
                                    ctx.moveTo(width * LINE_START, height * POSITION_PERCENT);
                                    ctx.lineTo(width * (1.0 - 2.0 * LINE_START), height * POSITION_PERCENT);
                                    ctx.stroke();
                                }
                            }
                        }
                    }

				}

                //center
                onCountChanged: {
                    view.width = manager.thumbSize.width * count;
                    view.x = (parent.width - view.width) / 2;
                    plusBtn.visible = count < 4;
                    grid.rows = $Model.getCalculateRowCount(currentScreen,$Model.currentIndex()+1);
                    grid.columns = $Model.getCalculateColumnsCount(currentScreen,$Model.currentIndex()+1);
                    grid.rowSpacing = (root.height - view.height)/$Model.getCalculateRowCount(currentScreen,$Model.currentIndex()+1)/5;
                    grid.columnSpacing = root.width*5/7/$Model.getCalculateColumnsCount(currentScreen,$Model.currentIndex()+1)/5;
					//default value 1
                    windowThumbnail.model = $Model.windows(currentScreen, $Model.currentIndex()+1);
                }


				Connections {
					target: $Model;
					onCurrentIndexChanged: {
                        grid.rows = $Model.getCalculateRowCount(currentScreen,$Model.currentIndex()+1);
                        grid.columns = $Model.getCalculateColumnsCount(currentScreen,$Model.currentIndex()+1);
                        grid.rowSpacing = (root.height - view.height)/$Model.getCalculateRowCount(currentScreen,$Model.currentIndex()+1)/5;
                        grid.columnSpacing = root.width*5/7/$Model.getCalculateColumnsCount(currentScreen,$Model.currentIndex()+1)/5;
						windowThumbnail.model = $Model.windows(currentScreen, currentIndex + 1);
					}     
				}
            }

            Button {
                id: plusBtn;
                text: "+";
                anchors.top: parent.top;
                anchors.right: parent.right;
                width: manager.thumbSize.width; 
                height: manager.thumbSize.height;
                onClicked: {
                    $Model.append();
                }

                DropArea {
                    anchors.fill: plusBtn;
                    onEntered: console.log("entered")
                    onDropped: {
                        var winId = drag.source.winId;
                        $Model.append();
                        var currentDesktop = $Model.rowCount();
                        qmlRequestMove2Desktop(currentScreen, currentDesktop, winId);
                        $Model.setCurrentIndex(currentDesktop - 1);
                    }
                }
            }

			//window thumbnail
            GridLayout {
                id:grid
                x: screenWidth/7;
                y: view.y + view.height;
                width: screenWidth*5/7;
                height: screenHeight - view.height-15;
                columns : $Model.getCalculateColumnsCount(currentScreen,$Model.currentIndex()+1);

				Repeater {
					id: windowThumbnail;
                    PlasmaCore.WindowThumbnail {
                        Layout.fillWidth: true;
                        Layout.fillHeight: true;
                        winId: modelData;
                        Drag.active: dragArea.drag.active
                        Drag.hotSpot.x: 10
                        Drag.hotSpot.y: 10

                        MouseArea {
                            id: dragArea
                            anchors.fill: parent
                            onReleased: parent.Drag.drop()
                            drag.target: parent

                            acceptedButtons: Qt.LeftButton| Qt.RightButton;
                            hoverEnabled: true;

                            onEntered: {
                                $Model.setCurrentSelectIndex(modelData);
                            }

                            onClicked: {
                                $Model.setCurrentSelectIndex(modelData);
                            }

                        }
                        Rectangle {
                            id: closeClientBtn;
                            anchors.right: parent.right;
                            width: closeClientBtnIcon.width;
                            height: closeClientBtnIcon.height;
                            color: "transparent";
                            Image {
                                id: closeClientBtnIcon;
                                source: "qrc:///icons/data/close_normal.svg"
                            }
                            MouseArea {
                                anchors.fill: closeClientBtn;
                                onClicked: {
                                    $Model.removeClient(currentScreen,$Model.currentIndex()+1,index);
                                }
                            }
                        }
                }
            }
            }
        }
    }

	Component.onCompleted: {
		for (var i = 0; i < $Model.numScreens(); ++i) {
			var geom = $Model.screenGeometry(i);
			var src = 
				'import QtQuick 2.0;' +
				'Loader {' + 
				'	x: ' + geom.x + ';' + 
				'	property int screenWidth: ' + geom.width + ';' +
                '   property int screenHeight: '+ geom.height + ';'+
				'	height: 260;' +
				'	property int currentScreen: ' + i + ';' +
				'	sourceComponent: desktopThumbmailView;' + 
				'}';
			Qt.createQmlObject(src, root, "dynamicSnippet");
		}	
	}
}
