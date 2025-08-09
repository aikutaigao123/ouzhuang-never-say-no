import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("隐私政策")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    Text("最后更新：2025年1月")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("欢迎使用我们的位置匹配应用。我们非常重视您的隐私保护，本隐私政策详细说明了我们如何收集、使用和保护您的个人信息。")
                        .font(.body)
                    
                    Text("通过使用本应用，您同意我们按照本隐私政策收集和使用您的信息。")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("1. 我们收集的信息")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("• 位置信息（精确/近似）：用于“位置记录匹配”，即基于您在使用时生成的位置记录进行匹配，而不是实时位置的持续共享或展示；仅在您点击“寻找”并授权定位后获取，不在后台持续定位")
                        .font(.body)
                    Text("• 用户标识：Apple ID 标识（经 Apple 授权）或设备标识符（用于游客登录及防滥用）")
                        .font(.body)
                    Text("• 用户资料：昵称、头像（emoji 形式）、邮箱地址（可选）")
                        .font(.body)
                    Text("• 设备信息：设备型号、系统版本、时区，仅用于问题排查与匹配纠偏")
                        .font(.body)
                    Text("• 使用数据：应用使用统计、匹配历史（用于提升匹配质量与防刷）")
                        .font(.body)
                    
                    Text("2. 信息使用目的")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("• 提供与优化位置匹配服务")
                        .font(.body)
                    Text("• 改善用户体验")
                        .font(.body)
                    Text("• 技术支持和故障排除")
                        .font(.body)
                    Text("• 安全保护、防止欺诈与滥用（如黑名单、限制频率）")
                        .font(.body)
                    Text("• 法律合规要求")
                        .font(.body)
                    
                    Text("3. 信息共享")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("我们不会出售您的个人信息。我们仅在以下情况下共享最小化数据：")
                        .font(.body)
                    
                    Text("• 获得您的明确同意")
                        .font(.body)
                    Text("• 法律要求或政府机构要求")
                        .font(.body)
                    Text("• 保护我们的权利和安全")
                        .font(.body)
                    Text("• 与可信赖的服务提供商合作（如 LeanCloud 作为数据托管与后端服务提供商；Apple 作为登录与支付服务提供商）")
                        .font(.body)
                    Text("• 第三方服务仅按我们的指示处理数据，受合同约束且不得用于与本应用无关的用途")
                        .font(.body)
                    
                    Text("4. 数据安全")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("• 使用 Apple Keychain Services 加密存储敏感信息")
                        .font(.body)
                    Text("• 采用 HTTPS 加密传输数据")
                        .font(.body)
                    Text("• 定期安全审计和更新")
                        .font(.body)
                    Text("• 限制员工访问用户数据")
                        .font(.body)
                    
                    Text("5. 数据保留")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("我们仅在达成目的所需期限内保留数据：例如位置记录用于匹配与风控，超期将归档或删除；当您提交删除账户请求通过审核后，我们将在合理期限内删除或匿名化您的相关数据。")
                        .font(.body)
                    
                    Text("6. 您的权利")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("• 访问和查看：在应用内查看基本资料与匹配历史")
                        .font(.body)
                    Text("• 更正：可在应用内修改昵称与头像")
                        .font(.body)
                    Text("• 删除：在应用内发起“删除账户”请求（路径：个人信息/设置 → 删除账户），我们将在法定/合理期限内处理")
                        .font(.body)
                    Text("• 撤回同意：可在系统设置中关闭定位权限，或停止使用相关功能")
                        .font(.body)
                    Text("• 数据可携带性")
                        .font(.body)
                    Text("• 投诉与申诉：如对我们的处理有异议，可通过下述邮箱联系我们")
                        .font(.body)
                    
                    Text("7. 儿童隐私")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("本应用不面向13岁以下的儿童。我们不会故意收集13岁以下儿童的个人信息。如果您发现我们收集了儿童信息，请立即联系我们。")
                        .font(.body)
                    
                    Text("8. 第三方服务")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("我们使用以下第三方服务：")
                        .font(.body)
                    Text("• LeanCloud：数据存储和云服务")
                        .font(.body)
                    Text("• Apple Sign In：用户认证")
                        .font(.body)
                    Text("• 这些服务有各自的隐私政策与数据处理条款，建议您一并查阅")
                        .font(.body)

                    Text("9. 数据存储与跨境")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("• 数据主要托管在 LeanCloud 提供的中国区节点（CN 区域）")
                        .font(.body)
                    Text("• 我们采取传输与存储加密，并按最小必要原则访问")
                        .font(.body)

                    Text("10. 追踪与个性化广告")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("• 本应用不进行跨应用追踪，不使用第三方广告 SDK 进行个性化广告投放")
                        .font(.body)
                    Text("• 若未来变更，我们将征求您的同意并更新本政策")
                        .font(.body)
                    
                    Text("11. 政策更新")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("我们可能会不时更新本隐私政策。重大变更将通过应用内通知告知您（不使用电子邮件通知）。")
                        .font(.body)
                    
                    Text("12. 联系我们")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("如果您对本隐私政策有任何疑问，请通过以下方式联系我们：")
                        .font(.body)
                    Text("• 邮箱：928322941@qq.com")
                        .font(.body)
                    // 应用内反馈已移除
                    
                    Text("感谢您信任我们保护您的隐私。我们将继续努力为您提供安全、可靠的服务。")
                        .font(.body)
                        .italic()
                        .padding(.top, 20)
                }
                .padding()
            }
            .navigationTitle("隐私政策")
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
    PrivacyPolicyView()
} 