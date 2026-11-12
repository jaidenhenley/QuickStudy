# QuickStudy Korean (ko) glossary

Voice: 해요체, warm and short. Buttons are noun or verb-stem phrases (Apple style: 저장, 다시 시도, 카드 저장). Alert titles use the Apple "~할 수 없음" form; body copy and import-failure cards use 해요체 ("~할 수 없어요"). Instructions use "-하세요". VoiceOver hints use 해요체 statements ("보관함을 열어요").

Particles: after `%@` and numbers, sentences are built so that no alternating particle (을/를, 이/가, 은/는, 와/과, (으)로) follows a placeholder. Counted nouns go before the number with a fixed counter (`카드 %lld장`, `세트 %lld개`, `%lld페이지`, `%lld회`), so any particle attaches to the counter, not the number. After titles, `‘%@’ 세트를…` / `“%@”에…` / `%@에서` / `%@ 관련` are used; 에, 에서, 관련 have no batchim alternation.

No plural forms (Korean has none); every plural key is a plain string.

| English | Korean | Why |
|---|---|---|
| flashcard(s) | 플래시카드 | Chosen over 암기 카드. It is the term Korean study apps and App Store listings use, it matches the in-app short form 카드, and the app also quizzes concepts, not only rote memorization (암기). 암기카드 goes in the keywords for search. |
| card | 카드 (counter 장) | Short form everywhere in UI; 장 is the natural counter for cards. |
| set / study set | 세트 / 학습 세트 (counter 개) | Quizlet-style term Korean students already know. |
| New Set | 새 세트 | |
| draft (noun) | 초안 | Standard term for an unfinished written draft. |
| draft (verb), drafting | 초안 작성 / 초안을 만들다; 초안 작성 중 | "작성" for status labels, "만들어요" in sentences for warmth. |
| Drafts are kept | 초안은 그대로 유지돼요 | |
| generate / generation | 생성 (counter 회) | "free generations" is a counted quota, so 무료 생성 10회. |
| free generation | 무료 생성 | |
| regenerate | 다시 생성 | |
| session | 세션 | Already common in Korean apps; 오늘의 세션 for TODAY'S SESSION. |
| streak | 연속 학습 (일 수: %lld일 연속 학습) | Duolingo-style phrasing understood by all students; avoids the slang loanword 스트릭. |
| Streak Freeze | 연속 학습 보호권 (short: 보호권) | Describes what it does (protects the streak) and is a countable item (개). |
| due | 복습 / 복습할 카드 | In spaced repetition, "due" means due for review. Badge: 복습 %lld. |
| review (spaced repetition) | 복습 | Studying again. |
| review (drafted cards before saving) | 검토 | Checking/approving content. Kept distinct from 복습 on purpose. |
| Review Cards | 카드 검토 | |
| weakest card | 가장 취약한 카드 | |
| toughest cards | 자주 틀리는 카드 | Distinguishes the Stats list from Today's single weakest card. |
| mastered | 암기 완료 | Short, student-natural, fits a filter chip. |
| in progress (filter) | 학습 중 | |
| Needs reinforcement | 다시 볼 카드 | Natural header for cards that need more work. |
| quiz | 퀴즈 | |
| question / answer | 문제 / 답 | Exam vocabulary students use. |
| correct / incorrect | 정답 / 오답 | |
| Why / Why? | 이유 / 왜? | Header vs. tiny pill. |
| hint | 힌트 | |
| source (of a card) | 출처 | |
| source (material you import) | 자료 / 학습 자료 | "Try a different source" = 다른 자료. |
| passage | 해당 부분 | "the passage this card came from" = 이 카드가 나온 부분; Show Passage = 해당 부분 보기. |
| excerpt | 발췌문 | |
| page; p.%lld pill | 페이지; %lld쪽 | 쪽 is the short Korean page counter for the tiny pill. |
| Library | 보관함 | Apple's Korean term for Library (Photos, Music, Books). |
| Today | 오늘 | |
| Stats | 통계 | |
| scan / Scan Document | 스캔 / 문서 스캔 | Apple Notes uses 문서 스캔. |
| paste / Paste Text | 붙여넣기 / 텍스트 붙여넣기 | Apple term. |
| import | 가져오기 | Apple term. |
| photo library | 사진 보관함 | Apple term. |
| Files / Photos / Camera / Notes app | 파일 / 사진 / 카메라 / 메모 | Apple app names in Korean. |
| notes (the user's) | 노트 | Neutral for typed and handwritten notes; 메모 is reserved for the Notes app. |
| type cards / manual cards | 카드 직접 입력 / 직접 만든 카드 | |
| term / definition | 용어 / 정의 | |
| cloud | 클라우드 | |
| on-device | 기기 내 | Apple Korea's phrasing for on-device processing. |
| on this iPhone | 이 iPhone에서 | |
| QuickStudy server | QuickStudy 서버 | |
| Apple's Private Cloud Compute | Apple의 Private Cloud Compute | Name untranslated per brief. |
| Anthropic's Claude | Anthropic의 Claude | |
| spaced repetition | 간격 반복 | Standard Korean term. |
| sample / demo set | 샘플 세트 | Single term for both "sample" and "demo". |
| Settings | 설정 | Apple. |
| Done / Cancel / Delete / Edit / Save | 완료 / 취소 / 삭제 / 편집 / 저장 | Apple. |
| Try Again | 다시 시도 | Apple. |
| OK / Close / Dismiss | 확인 / 닫기 / 닫기 | Apple. |
| Undo | 실행 취소 | Apple. |
| Discard | 폐기 | Apple ("변경 사항 폐기"). |
| Replace | 바꾸기 | More natural than Finder's 대치 in a draft dialog. |
| Rename | 이름 변경 | Apple. |
| Allow / Not Now | 허용 / 나중에 | Apple. |
| Restore Purchases | 구입 항목 복원 | Apple. |
| Restore Subscription (StoreKit button) | 구독 복원 | The paywall is SubscriptionStoreView, whose restore button is labelled 구독 복원 in Korean (StoreKit RESTORE_SUBSCRIPTION_LABEL). Error copy that names the button uses ‘구독 복원’. |
| Manage Subscription | 구독 관리 | Apple. |
| Upgrade to Pro | Pro로 업그레이드 | |
| purchase | 구입 | Apple uses 구입, not 구매. |
| Apple Account | Apple 계정 | Apple. |
| Privacy Policy | 개인정보 처리방침 | Korean legal standard term, used by Apple Korea. |
| What's New | 새로운 기능 | Apple. |
| elapsed time | 경과 시간 | |
| offline | 오프라인 | |
| Double tap to edit (hint) | 편집하려면 이중 탭하세요 | Apple VoiceOver uses 이중 탭. |
