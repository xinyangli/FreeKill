import QtQuick
import QtQuick.Layouts
import "../skin-bank.js" as SkinBank

Item {
  id: root
  width: bg.width
  height: bg.height

  Image {
    id: bg
    x: -32
    height: 69
    source: SkinBank.LOBBY_IMG_DIR + "profile"
    fillMode: Image.PreserveAspectFit
  }

  RowLayout {
    Item { Layout.preferredWidth: 16 }

    Image {
      Layout.preferredWidth: 64
      Layout.preferredHeight: 64
      source: SkinBank.getGeneralPicture(Self.avatar)
      sourceSize.width: 250
      sourceSize.height: 292
      sourceClipRect: Qt.rect(61, 0, 128, 128)

      Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 1
      }
    }

    Item { Layout.preferredWidth: 8 }

    Text {
      Layout.alignment: Qt.AlignTop
      text: Self.screenName
      font.pixelSize: 22
      font.family: fontLibian.name
      color: "#F0DFAF"
      style: Text.Outline
    }
  }

  TapHandler {
    onTapped: {
      lobby_dialog.source = "LobbyElement/EditProfile.qml";
      lobby_drawer.open();
    }
  }
}
