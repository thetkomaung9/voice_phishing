package com.safecall.ai

data class PhishingResult(
    val riskLevel: Int,
    val isPhishing: Boolean,
    val alertLevel: String,
    val message: String,
    val reason: String,
    val recommendedAction: String,
    val score: Int
)

class PhishingDetector {

    private data class Rule(val pattern: Regex, val score: Int, val reason: String)

    private val rules = listOf(
        // ── English ──────────────────────────────────────────────────
        Rule(Regex("\\botp\\b", RegexOption.IGNORE_CASE), 35, "OTP request"),
        Rule(Regex("verification\\s+code", RegexOption.IGNORE_CASE), 35, "Verification code request"),
        Rule(Regex("bank\\s+account", RegexOption.IGNORE_CASE), 30, "Bank account mention"),
        Rule(Regex("credit\\s+card|card\\s+number", RegexOption.IGNORE_CASE), 30, "Card number request"),
        Rule(Regex("\\bpassword\\b|\\bpin\\b", RegexOption.IGNORE_CASE), 25, "Password/PIN request"),
        Rule(Regex("transfer|wire\\s+money", RegexOption.IGNORE_CASE), 25, "Money transfer"),
        Rule(Regex("account.*blocked|blocked.*account", RegexOption.IGNORE_CASE), 30, "Account blocked threat"),
        Rule(Regex("urgent|immediately|right\\s+now|act\\s+now", RegexOption.IGNORE_CASE), 20, "Urgency pressure"),
        Rule(Regex("\\bpolice\\b|\\bcourt\\b|\\barrest\\b|\\bwarrant\\b", RegexOption.IGNORE_CASE), 25, "Authority impersonation"),
        Rule(Regex("install.*app|remote.*access|anydesk|teamviewer", RegexOption.IGNORE_CASE), 40, "Remote access/app install"),
        Rule(Regex("click.*link|follow.*link", RegexOption.IGNORE_CASE), 30, "Suspicious link"),
        Rule(Regex("social\\s+security|passport\\s+number|id\\s+number", RegexOption.IGNORE_CASE), 35, "ID number request"),

        // ── Korean ───────────────────────────────────────────────────
        Rule(Regex("인증\\s*번호|인증코드|인증\\s*코드"), 35, "Korean: auth/OTP code"),
        Rule(Regex("계좌번호|통장번호|계좌\\s*이체"), 35, "Korean: account number"),
        Rule(Regex("비밀번호|패스워드"), 25, "Korean: password"),
        Rule(Regex("신분증|주민번호|여권번호"), 35, "Korean: ID number"),
        Rule(Regex("대출|저금리.*대출|긴급.*대출"), 20, "Korean: loan offer"),
        Rule(Regex("금융감독원|금감원|검사|수사관|경찰청"), 30, "Korean: authority impersonation"),
        Rule(Regex("계좌가\\s*정지|정지.*계좌|카드.*정지"), 30, "Korean: account blocked threat"),
        Rule(Regex("지금\\s*바로|즉시|급히"), 20, "Korean: urgency"),
        Rule(Regex("송금|이체\\s*해"), 25, "Korean: transfer money"),
        Rule(Regex("앱\\s*설치|원격.*제어|원격.*접속"), 40, "Korean: remote access/app"),

        // ── Burmese ──────────────────────────────────────────────────
        Rule(Regex("အကောင့်|ဘဏ်"), 20, "Burmese: account/bank"),
        Rule(Regex("လျှို့ဝှက်ကုဒ်"), 35, "Burmese: secret code/OTP"),
        Rule(Regex("လွှဲပြောင်း|ငွေ.*လွှဲ"), 25, "Burmese: money transfer"),

        // ── Vietnamese ───────────────────────────────────────────────
        Rule(Regex("mã\\s+otp|mã\\s+xác\\s+nhận", RegexOption.IGNORE_CASE), 35, "Vietnamese: OTP"),
        Rule(Regex("tài\\s+khoản|ngân\\s+hàng", RegexOption.IGNORE_CASE), 25, "Vietnamese: bank account"),
        Rule(Regex("chuyển\\s+tiền|giao\\s+dịch", RegexOption.IGNORE_CASE), 25, "Vietnamese: transfer"),
        Rule(Regex("cảnh\\s+sát|tòa\\s+án", RegexOption.IGNORE_CASE), 25, "Vietnamese: authority"),
    )

    fun analyze(transcript: String): PhishingResult {
        if (transcript.isBlank()) {
            return PhishingResult(0, false, "none", "No risk detected", "No transcript", "continue", 0)
        }

        var totalScore = 0
        val hits = mutableListOf<String>()

        for (rule in rules) {
            if (rule.pattern.containsMatchIn(transcript)) {
                totalScore += rule.score
                hits += rule.reason
            }
        }

        totalScore = totalScore.coerceAtMost(100)

        return when {
            totalScore >= 70 -> PhishingResult(
                riskLevel = 3,
                isPhishing = true,
                alertLevel = "high",
                message = "Possible scam! Hang up immediately!",
                reason = hits.joinToString(", "),
                recommendedAction = "hang up immediately",
                score = totalScore
            )
            totalScore >= 45 -> PhishingResult(
                riskLevel = 2,
                isPhishing = true,
                alertLevel = "medium",
                message = "This call may be a scam. Do not share personal info.",
                reason = hits.joinToString(", "),
                recommendedAction = "be careful",
                score = totalScore
            )
            totalScore >= 20 -> PhishingResult(
                riskLevel = 1,
                isPhishing = false,
                alertLevel = "low",
                message = "This call seems unusual. Be careful.",
                reason = hits.joinToString(", "),
                recommendedAction = "be careful",
                score = totalScore
            )
            else -> PhishingResult(
                riskLevel = 0,
                isPhishing = false,
                alertLevel = "none",
                message = "No risk detected",
                reason = "No suspicious patterns",
                recommendedAction = "continue",
                score = totalScore
            )
        }
    }
}
