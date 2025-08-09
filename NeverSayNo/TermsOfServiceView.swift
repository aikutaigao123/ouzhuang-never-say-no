import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("用户协议")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    Text("最后更新：2025年1月")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("欢迎使用我们的位置匹配应用。本用户协议（以下简称\"协议\"）是您与我们之间关于使用本应用服务所达成的协议。")
                        .font(.body)
                    
                    Text("通过使用本应用，您表示您已阅读、理解并同意遵守本协议的所有条款。")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("1. 服务描述")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("本应用提供基于位置的用户匹配服务，帮助用户找到附近的其他用户。服务包括但不限于：")
                        .font(.body)
                    
                    Text("• 位置匹配服务")
                        .font(.body)
                    Text("• 用户资料管理")
                        .font(.body)
                    Text("• 匹配历史记录")
                        .font(.body)
                    Text("• 虚拟货币系统")
                        .font(.body)
                    
                    Text("2. 用户责任")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("使用本应用时，您同意：")
                        .font(.body)
                    
                    Text("• 提供真实、准确的个人信息")
                        .font(.body)
                    Text("• 遵守所有适用的法律法规")
                        .font(.body)
                    Text("• 尊重其他用户的隐私和权利")
                        .font(.body)
                    Text("• 不得发布不当、违法或有害内容")
                        .font(.body)
                    Text("• 不得滥用服务或干扰其他用户")
                        .font(.body)
                    Text("• 保护您的账户安全")
                        .font(.body)
                    
                    Text("3. 禁止行为")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("您不得从事以下行为：")
                        .font(.body)
                    
                    Text("• 发布虚假、误导或欺诈性信息")
                        .font(.body)
                    Text("• 骚扰、威胁或恐吓其他用户")
                        .font(.body)
                    Text("• 发布色情、暴力或仇恨内容")
                        .font(.body)
                    Text("• 冒充他人或虚假身份")
                        .font(.body)
                    Text("• 传播病毒或恶意软件")
                        .font(.body)
                    Text("• 未经授权访问系统或数据")
                        .font(.body)
                    Text("• 商业用途或批量注册账户")
                        .font(.body)
                    
                    Text("4. 知识产权")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("• 应用及其内容受知识产权法保护")
                        .font(.body)
                    Text("• 您保留您发布内容的权利")
                        .font(.body)
                    Text("• 您授予我们使用您内容的许可")
                        .font(.body)
                    Text("• 不得复制、修改或分发应用代码")
                        .font(.body)
                    
                    Text("5. 隐私保护")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("我们重视您的隐私保护，具体政策请参见《隐私政策》。您同意我们按照隐私政策收集、使用和保护您的个人信息。")
                        .font(.body)
                    
                    Text("6. 服务变更")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("• 我们保留随时修改或终止服务的权利")
                        .font(.body)
                    Text("• 重大变更会提前通知用户")
                        .font(.body)
                    Text("• 服务中断时我们会尽力恢复")
                        .font(.body)
                    Text("• 我们不承担因服务中断造成的损失")
                        .font(.body)
                    
                    Text("7. 付费服务")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("• 部分服务需要购买虚拟货币")
                        .font(.body)
                    Text("• 虚拟货币不可退款或转让")
                        .font(.body)
                    Text("• 价格可能随时调整")
                        .font(.body)
                    Text("• 购买后立即生效")
                        .font(.body)
                    Text("• 遵守 Apple 的付费服务条款")
                        .font(.body)
                    
                    Text("8. 免责声明")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("• 服务按\"现状\"提供，不提供任何保证")
                        .font(.body)
                    Text("• 我们不保证服务无中断或无错误")
                        .font(.body)
                    Text("• 用户自行承担使用风险")
                        .font(.body)
                    Text("• 我们不承担间接或偶然损失")
                        .font(.body)
                    Text("• 其他用户的行为不代表我们的立场")
                        .font(.body)
                    
                    Text("9. 责任限制")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("在法律允许的最大范围内，我们的责任不超过您支付的费用金额。某些司法管辖区不允许责任限制，因此这些限制可能不适用于您。")
                        .font(.body)
                    
                    Text("10. 协议终止")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("• 您可以随时停止使用服务")
                        .font(.body)
                    Text("• 我们可以在您违反协议时终止服务")
                        .font(.body)
                    Text("• 终止后某些条款仍然有效")
                        .font(.body)
                    Text("• 我们会删除您的账户数据")
                        .font(.body)
                    
                    Text("11. 争议解决")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("本协议受中华人民共和国法律管辖。任何争议应通过友好协商解决，协商不成的，提交有管辖权的人民法院解决。")
                        .font(.body)
                    
                    Text("12. 协议更新")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("我们可能会不时更新本协议。重大变更时，我们会通过应用内通知或电子邮件通知您。继续使用服务表示您同意新条款。")
                        .font(.body)
                    
                    Text("13. 联系我们")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("如果您对本协议有任何疑问，请通过以下方式联系我们：")
                        .font(.body)
                    Text("• 邮箱：928322941@qq.com")
                        .font(.body)
                    // 网站信息已移除
                    Text("• 应用内反馈")
                        .font(.body)
                    
                    Text("感谢您选择我们的服务。我们致力于为您提供安全、可靠的位置匹配体验。")
                        .font(.body)
                        .italic()
                        .padding(.top, 20)
                }
                .padding()
            }
            .navigationTitle("用户协议")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TermsOfServiceView()
} 