import Foundation
import simd
import RealityKit

class CountdownAnimation: Animation {
    // 需要容器偵測
    override var requiresContainerDetection: Bool { true }
    override var containerType: Container? { container }

    private let minutes: Int
    private let container: Container
    private let modelEntity: Entity

    init(minutes: Int,
         container: Container,
         scale: Float = 0.1,
         isRepeat: Bool = false) {
        self.minutes = minutes
        self.container = container

        // 建構倒數文字的 3D 模型
        let textMesh = MeshResource.generateText(
            "\(minutes)",
            extrusionDepth: 0.01,
            font: .systemFont(ofSize: 0.5),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byWordWrapping
        )
        let material = SimpleMaterial()
        self.modelEntity = ModelEntity(mesh: textMesh, materials: [material])

        // 傳遞 type, scale, isRepeat 給父類
        super.init(type: .countdown, scale: scale, isRepeat: isRepeat)
    }

    // 在 Anchor 上加入文字模型並運行動畫
    override func applyAnimation(to anchor: AnchorEntity, on arView: ARView) {
        let entity = modelEntity.clone(recursive: true)
        entity.scale = SIMD3(repeating: scale)
        entity.position.y += 0.05
        anchor.addChild(entity)
        // 載入倒數動畫的 usdz 模型（可自訂名稱，例如 countdown.usdz）
        if let url = Bundle.main.url(forResource: "countdown", withExtension: "usdz") {
            do {
                let usdzEntity = try Entity.load(contentsOf: url)
                usdzEntity.scale = SIMD3(repeating: scale)
                anchor.addChild(usdzEntity)
                if let animationResource = usdzEntity.availableAnimations.first {
                    usdzEntity.playAnimation(animationResource, transitionDuration: 0.0, startsPaused: false)
                }
            } catch {
                print("❌ 無法載入 countdown.usdz：\(error)")
            }
        }
    }

    // 根據邊界框更新世界座標
    override func updateBoundingBox(rect: CGRect) {
        let worldPos = worldPosition(from: rect,
                                     offsetY: Float(rect.height / 2 + 0.05))
        anchorEntity?.transform.translation = worldPos
    }

    
    /// 將 2D 匡轉為 3D 世界座標 (暫時使用 anchorEntity 位置加 Y 偏移)
    private func worldPosition(from rect: CGRect, offsetY: Float = 0) -> SIMD3<Float> {
        // 如果已有 anchorEntity，則在其基礎上位移，否則回傳原點偏移
        let base = anchorEntity?.transform.translation ?? SIMD3<Float>(0, 0, 0)
        return SIMD3<Float>(base.x,
                             base.y + offsetY,
                             base.z )
    }
}
