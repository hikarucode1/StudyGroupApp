import Foundation
import StoreKit

// MARK: - プレミアム商品情報
struct PremiumProduct: Identifiable {
    let id: String
    let product: Product
    let isPopular: Bool
    
    var displayName: String {
        product.displayName
    }
    
    var description: String {
        product.description
    }
    
    var price: Decimal {
        product.price
    }
    
    var formattedPrice: String {
        product.displayPrice
    }
    
    var subscriptionPeriod: String {
        if product.subscription?.subscriptionPeriod.unit == .month {
            return "月額"
        } else if product.subscription?.subscriptionPeriod.unit == .year {
            return "年額"
        }
        return ""
    }
}

// MARK: - プレミアム購入管理
@MainActor
class PremiumManager: NSObject, ObservableObject {
    @Published var products: [PremiumProduct] = []
    @Published var isPremium: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var productIDs = [
        "com.hikaru.StudyGroupApp.premium.monthly",
        "com.hikaru.StudyGroupApp.premium.yearly"
    ]
    
    private var updateListenerTask: Task<Void, Error>?
    
    override init() {
        super.init()
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await updatePremiumStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - 商品の読み込み
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let storeProducts = try await Product.products(for: productIDs)
            
            products = storeProducts.map { product in
                let isPopular = product.id.contains("yearly")
                return PremiumProduct(id: product.id, product: product, isPopular: isPopular)
            }
            
            // 人気商品を最初に表示
            products.sort { $0.isPopular && !$1.isPopular }
            
        } catch {
            errorMessage = "商品の読み込みに失敗しました: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - 購入処理
    func purchase(_ product: PremiumProduct) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.product.purchase()
            
            switch result {
            case .success(let verification):
                // 購入の検証
                await handlePurchaseVerification(verification)
                
            case .userCancelled:
                errorMessage = "購入がキャンセルされました"
                
            case .pending:
                errorMessage = "購入が保留中です"
                
            @unknown default:
                errorMessage = "予期しないエラーが発生しました"
            }
            
        } catch {
            errorMessage = "購入に失敗しました: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - 購入検証
    private func handlePurchaseVerification(_ verification: VerificationResult<Transaction>) async {
        do {
            let transaction = try checkVerified(verification)
            
            // プレミアム状態を更新
            await updatePremiumStatus()
            
            // トランザクションを完了
            await transaction.finish()
            
        } catch {
            errorMessage = "購入の検証に失敗しました: \(error.localizedDescription)"
        }
    }
    
    // MARK: - 検証チェック
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PremiumError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - プレミアム状態の更新
    func updatePremiumStatus() async {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                // 有効なサブスクリプションがあるかチェック
                if transaction.revocationDate == nil {
                    isPremium = true
                    return
                }
            } catch {
                print("トランザクション検証エラー: \(error)")
            }
        }
        
        isPremium = false
    }
    
    // MARK: - トランザクション監視
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                await self.handleTransactionUpdate(result)
            }
        }
    }
    
    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        do {
            let transaction = try checkVerified(result)
            
            // プレミアム状態を更新
            await updatePremiumStatus()
            
            // トランザクションを完了
            await transaction.finish()
            
        } catch {
            print("トランザクション更新エラー: \(error)")
        }
    }
    
    // MARK: - 復元処理
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updatePremiumStatus()
            
            if isPremium {
                errorMessage = "購入が復元されました"
            } else {
                errorMessage = "復元する購入が見つかりませんでした"
            }
            
        } catch {
            errorMessage = "購入の復元に失敗しました: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

// MARK: - エラー定義
enum PremiumError: LocalizedError {
    case verificationFailed
    
    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "購入の検証に失敗しました"
        }
    }
} 