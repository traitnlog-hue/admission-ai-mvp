const $ = (id) => document.getElementById(id);
const subjects = ['korean','math','english','social','science'];
const mockSubjects = ['mockKorean','mockMath','mockEnglish','mockInquiry'];
const majorProfiles = {
  '컴퓨터': { keywords:['알고리즘','프로그래밍','코딩','데이터','정보','소프트웨어','ai','인공지능','수학'], core:['math','science'], label:'컴퓨터·소프트웨어' },
  '공학': { keywords:['설계','실험','제작','수학','물리','과학','코딩','탐구'], core:['math','science'], label:'공학' },
  '의학': { keywords:['생명','의료','보건','인체','화학','봉사','과학'], core:['science','english'], label:'의·보건' },
  '간호': { keywords:['생명','의료','보건','인체','봉사','건강','과학'], core:['science','english'], label:'간호·보건' },
  '경영': { keywords:['경제','경영','시장','통계','데이터','창업','사회','수학'], core:['math','social'], label:'경영·경제' },
  '교육': { keywords:['교육','수업','학습','멘토링','봉사','심리','국어'], core:['korean','social'], label:'교육' },
  '디자인': { keywords:['디자인','시각','제작','기획','콘텐츠','예술','창작'], core:['korean','social'], label:'디자인·예술' },
  default: { keywords:['탐구','분석','발표','프로젝트','기획','자료'], core:['korean','social'], label:'희망 전공' }
};
function val(id){ return Math.max(1, Math.min(9, Number($(id).value) || 5)); }
function avg(ids){ return ids.reduce((sum,id)=>sum+val(id),0)/ids.length; }
function scoreFromGrade(grade){ return Math.round(Math.max(0, Math.min(100, 112.5 - grade * 12.5))); }
function profileFor(major){ return Object.entries(majorProfiles).find(([key]) => major.includes(key))?.[1] || majorProfiles.default; }
function analyzeLocal(){
  const major = $('majorInput').value.trim() || '희망 전공'; const text = $('recordText').value.trim().toLowerCase(); const profile = profileFor(major);
  const schoolAvg = avg(subjects), mockAvg = avg(mockSubjects);
  const academic = scoreFromGrade(schoolAvg), csat = scoreFromGrade(mockAvg);
  const coreAvg = avg(profile.core), coreScore = scoreFromGrade(coreAvg);
  const hits = profile.keywords.filter(k => text.includes(k)).length;
  const record = Math.min(95, Math.round(48 + hits * 8 + Math.min(text.length / 40, 16)));
  const choice = Math.round(coreScore * .68 + record * .32);
  const tracks = { '학생부교과':Math.round(academic*.73 + coreScore*.27), '학생부종합':Math.round(academic*.32 + record*.43 + choice*.25), '정시':Math.round(csat*.82 + coreScore*.18), '논술':Math.round(csat*.46 + academic*.27 + coreScore*.27) };
  const sorted = Object.entries(tracks).sort((a,b)=>b[1]-a[1]);
  const [first, second] = sorted;
  const schoolVsMock = mockAvg - schoolAvg;
  const risks=[];
  if (mockAvg > 2.3) risks.push('수능최저가 있는 전형은 목표 등급과 실제 모의고사 추세를 별도로 점검하세요.');
  else risks.push('수능 경쟁력이 강점입니다. 수시 지원 시에도 수능최저 충족 가능성을 유지하세요.');
  if (record < 70) risks.push(`학생부에서 ${profile.label} 관련 탐구의 과정·결과·확장성을 더 구체적으로 남겨야 합니다.`);
  else risks.push('학생부에 전공 연결 키워드가 확인됩니다. 후속 탐구로 깊이와 일관성을 강화하세요.');
  if (coreAvg > schoolAvg + .25) risks.push('전공 핵심교과 성적이 전체 평균보다 약합니다. 다음 시험의 우선 보완 과목으로 설정하세요.');
  else risks.push('전공 핵심교과 성취가 안정적입니다. 세특에서 성취 근거를 연결하세요.');
  render({major, profile, schoolAvg, mockAvg, academic, csat, choice, record, tracks, first, second, schoolVsMock, risks, hits});
}
function apiPayload(){return {admission_year:Number($('admissionYear').value),grade:Number($('grade').value),major:$('majorInput').value.trim()||'희망 전공',school_grades:{korean:val('korean'),math:val('math'),english:val('english'),social:val('social'),science:val('science')},mock_grades:{korean:val('mockKorean'),math:val('mockMath'),english:val('mockEnglish'),inquiry:val('mockInquiry')},record_text:$('recordText').value.trim(),ai_record_analysis:false};}
async function analyze(){try{const response=await fetch('/api/analyze',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(apiPayload())});if(!response.ok)throw new Error('analysis failed');renderApi(await response.json());}catch(error){analyzeLocal();}}
function renderApi(data){
  const scoreMap=Object.fromEntries(data.scores.map(item=>[item.label,item.value]));
  const trackMap=Object.fromEntries(data.track_scores.map(item=>[item.label,item.value]));
  $('studentTitle').textContent=`${data.major} 지원 전략`;$('yearBadge').textContent=data.admission_year;
  $('resultIntro').textContent='FastAPI 규칙 엔진이 성적과 학생부 기록을 기준으로 산출한 전략 진단입니다.';
  $('scores').innerHTML=data.scores.map(item=>`<div class="score-card"><p>${item.label}</p><div class="score-num"><b>${item.value}</b><span>/100</span></div><div class="meter"><i style="width:${item.value}%"></i></div></div>`).join('');
  $('primaryStrategy').textContent=data.primary_strategy;$('strategyReason').textContent=data.primary_reason;$('secondaryStrategy').textContent=data.secondary_strategy;$('secondaryReason').textContent=data.secondary_reason;$('riskList').innerHTML=data.risks.map(item=>`<li>${item}</li>`).join('');
  $('recommendations').innerHTML=data.recommendations.map(item=>`<div class="sample-item"><div><b>${item.university} · ${item.department}</b><p>${item.track} / ${item.admission_type} · 테스트 데이터</p></div><span class="decision">${item.decision}</span></div>`).join('')||'<p>해당 연도 테스트 데이터가 없습니다.</p>';
  $('reportOverall').textContent=data.report.overall;$('reportGrades').textContent=data.report.grades;$('reportRecord').textContent=data.report.record;$('reportMajor').textContent=data.report.major;$('reportTrack').textContent=data.report.track;$('reportRisk').textContent=data.report.risk;$('reportAction').textContent=data.action_plan;
}
function render(d){
  $('studentTitle').textContent = `${d.major} 지원 전략`; $('yearBadge').textContent = $('admissionYear').value;
  $('resultIntro').textContent = `내신 평균 ${d.schoolAvg.toFixed(1)}등급 · 모의고사 평균 ${d.mockAvg.toFixed(1)}등급을 기준으로 한 전략 진단입니다.`;
  const scoreItems=[['학업역량',d.academic],['수능역량',d.csat],['과목선택',d.choice],['학생부역량',d.record]];
  $('scores').innerHTML=scoreItems.map(([name,value])=>`<div class="score-card"><p>${name}</p><div class="score-num"><b>${value}</b><span>/100</span></div><div class="meter"><i style="width:${value}%"></i></div></div>`).join('');
  $('primaryStrategy').textContent = `${d.first[0]} 중심 전략`;
  $('strategyReason').textContent = strategyReason(d.first[0],d);
  $('secondaryStrategy').textContent = `${d.second[0]} 병행 전략`;
  $('secondaryReason').textContent = `${d.second[0]} 적합도 ${d.second[1]}점으로 보조 지원축을 만들 수 있습니다.`;
  $('riskList').innerHTML=d.risks.map(x=>`<li>${x}</li>`).join('');
  $('reportOverall').textContent=`학업 ${d.academic} · 수능 ${d.csat} · 학생부 ${d.record}점. ${d.first[0]} 경로가 현재 우세합니다.`;
  $('reportGrades').textContent=`내신 평균 ${d.schoolAvg.toFixed(1)}등급. ${d.profile.label} 핵심교과는 ${scoreFromGrade(avg(d.profile.core))}점입니다.`;
  $('reportRecord').textContent=d.hits ? `전공 연결 키워드 ${d.hits}개가 확인됩니다. 활동 간 후속 질문을 준비하세요.` : '전공 관련 탐구의 문제의식·방법·결과를 세특에 구체적으로 남기세요.';
  $('reportMajor').textContent=`${d.major} 기준 핵심교과와 학생부 연결성은 ${d.choice}점입니다.`;
  $('reportTrack').textContent=Object.entries(d.tracks).map(([n,s])=>`${n} ${s}`).join(' · ');
  $('reportRisk').textContent=d.risks[0];
  $('reportAction').textContent=action(d);
  $('resultPanel').classList.add('updated');
}
function strategyReason(track,d){
  if(track==='정시') return `모의고사 경쟁력이 내신 대비 ${d.schoolVsMock < 0 ? '높고' : '안정적이고'}, 수능 실전 성과를 전략의 중심에 둘 수 있습니다.`;
  if(track==='학생부종합') return `전공 연계 활동과 기록의 맥락이 강점입니다. 탐구의 깊이를 이어가세요.`;
  if(track==='학생부교과') return `내신 평균과 핵심교과 성취가 안정적입니다. 대학별 반영 교과·수능최저를 확인하세요.`;
  return `교과 성취와 수능 역량의 균형이 좋습니다. 기출 풀이와 논증 훈련이 필요합니다.`;
}
function action(d){
  const weak = d.mockAvg > d.schoolAvg ? '모의고사 취약 과목의 오답 원인 정리와 주간 보완' : '내신 핵심교과의 다음 시험 목표 등급 설정';
  return `이번 달은 ${weak}, 다음 세특에는 ${d.major} 관련 탐구를 ‘질문–과정–결과’로 남기세요.`;
}
$('consultingForm').addEventListener('submit',(e)=>{e.preventDefault();if(!$('consent').checked){alert('학생부 텍스트 분석 동의가 필요합니다.');return;}analyze();$('resultPanel').scrollIntoView({behavior:'smooth',block:'start'});});
$('startBtn').addEventListener('click',()=>document.querySelector('.form-panel').scrollIntoView({behavior:'smooth',block:'start'}));
analyze();
