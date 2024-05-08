**********************************************************************
//Task：毕业论文一定要显著啊！
//做实证论文，先把结果跑出来，然后争取各类检验都能显著，开始写正文
//建议：先把要写的公式列出来，然后遍历各种可能的情况，调出最好的放在我们论文的list里面
**********************************************************************

// step 1 ：读入数据、指定面板与时间等前瞻性工作
clear
insheet using /Users/liuyulin/Desktop/毕业论文/Weather_invest/Stata_run/low_sensitive_version6.csv
//insheet using /Users/liuyulin/Desktop/毕业论文/Weather_invest/Stata_run/high_sensitive_version7.csv
//insheet using /Users/liuyulin/Desktop/毕业论文/Weather_invest/Stata_run/no_sensitive_version7.csv
//insheet using /Users/liuyulin/Desktop/毕业论文/Weather_invest/Stata_run/total_versio7.csv
//时间数据他会识别成文本，因此我们要重新处理下
gen time2 = date(time_str, "YMD")
format time2 %td
//如果把上述处理的数据直接读进去，Stata就会处理为以日度为频率的计量数据
//我们需要改为季度，同时Stata的日期准则是以1960年Q1为基期的，因此我们本质是在做加减法
gen time = qofd(time2) 
format time %tq 

//告诉Stata我们是面板数据的回归
xtset code time
// 此时读入的数据会告诉我们delta = 1 quater

//step2 ： 有一些变量需要计算
//这些是每个表都需要跑的
gen totalvalue_change_a = D.totalvalue_a / L.totalvalue_a - 1
gen totalvalue_change_b = D.totalvalue_b / L.totalvalue_b - 1
gen bulltime = 1
replace bulltime = 0 if time < 214 
replace bulltime = 0 if time > 234 & time<238
replace bulltime = 0 if time > 221 & time<226
//根据stata对变量的命名规则，1960Q1 = 0，推理出2010 Q1 = 200，2013 Q3 = 214
// 2015Q3 =222 ，2018 Q3 = 234。对应中国的牛熊市，为异质性检验做好准备
gen wet = 0
replace wet = 1 if province == "广东省"
replace wet = 1 if province == "广西壮族自治区"
replace wet = 1 if province == "湖南省"
replace wet = 1 if province == "江西省"
replace wet = 1 if province == "福建省"
replace wet = 1 if province == "海南省"
replace wet = 1 if province == "浙江省"
replace wet = 1 if province == "贵州省"
replace wet = 1 if province == "云南省"
replace wet = 1 if province == "湖北省"
replace wet = 1 if province == "江苏省"
replace wet = 1 if province == "安徽省"
replace wet = 1 if province == "四川省"
//上述是对潮湿地区的判断，一共四种地形
gen halfwet = 0
replace halfwet = 1 if province == "黑龙江省"
replace halfwet = 1 if province == "辽宁省"
replace halfwet = 1 if province == "吉林省"
replace halfwet = 1 if province == "山东省"
replace halfwet = 1 if province == "河南省"
replace halfwet = 1 if province == "陕西省"
replace halfwet = 1 if province == "四川省"
replace halfwet = 1 if province == "安徽省"
replace halfwet = 1 if province == "江苏省"
replace halfwet = 1 if province == "西藏省"
replace halfwet = 1 if province == "河北省"
replace halfwet = 1 if province == "山西省"

gen halfdry = 0
replace halfdry = 1 if province == "内蒙古自治区"
replace halfdry = 1 if province == "宁夏回族自治区"
replace halfdry = 1 if province == "山西省"
replace halfdry = 1 if province == "陕西省"
replace halfdry = 1 if province == "甘肃省"
replace halfdry = 1 if province == "青海省"
replace halfdry = 1 if province == "西藏自治区"
replace halfdry = 1 if province == "新疆维吾尔自治区"

gen dry = 0
gen dry_med = halfwet + halfdry + wet
replace dry = 1 if dry_med == 0

//这些是4\5\6\7表要跑的（不需要的时候用两行星号*就注释掉好了）
gen poid = inddirectnumber / boardscale
gen k7 = (D.y0601b / L.y0601b - 1) / (D.income_change_a / L.income_change_a - 1)
gen sa = D.k1 + D.k2 + D.k3 + D.k4 + D.k5 + D.k6
gen k1_tag = 1
replace k1_tag = 0 if D.k1 < 0
gen k2_tag = 1
replace k2_tag = 0 if D.k2 < 0
gen k3_tag = 1
replace k3_tag = 0 if D.k3 < 0
gen k7_tag = 1
replace k7_tag = 0 if D.k7 < 0
gen k8_tag = 1
replace k8_tag = 0 if D.k8 < 0
gen k9_tag = 1
replace k9_tag = 0 if D.k9 < 0
gen sd_measure = k1_tag + k2_tag + k3_tag + k7_tag + k8_tag + k9_tag
gen sd = 1
replace sd = 0 if sd_measure < 3
//经过上述代码后，对所有变量的导入、筛选就已经完备了，那么要不要缩尾
//从目前的结果来看不用，我们依然把代码先放上备用

//foreach var of varlist rain totalvalue_change_a {
//    sum `var', detail
//    replace `var' = r(p5) if `var' < r(p5)
//    replace `var' = r(p95) if `var' > r(p95)
//}

//Step 3: 回归前的基本统计，描述性统计要做吧，数据的回归前检验要做吧（可以等回归完敲定了所有的变量后再反过来做这个），也应该把控制变量先放上了
//先放一个描述性的统计表，要放其他数据随时加上即可
tabstat totalvalue_change_a roa rain extreme_more_data extreme_less_data ratefix lever , statistics(n mean sd p1 median p99 )
//在这里我们放一下控制变量合集，目的是方便后续用$命令来随时定义所有控制变量，方便快捷（比如根据数学知识遍历出所有的控制变量可能情况又比如用一下oneclick）
//控制变量集1
global controls1 "growth_rate_fix lever currentratio ownershipconcentration age asset_liability poid"
//控制变量集2，和1相比去掉了杠杆，不然跑机制分析的时候可能会出bug
global controls2 "growth_rate_fix currentratio ownershipconcentration age asset_liability poid"
//控制变量集3
global controls3 "roa roe growth_rate_fix currentratio ownershipconcentration age asset_liability poid"

//Step4 主效应回归（由于涉及到分组，我们可能需要不断改开头的引入什么文件）
// 首先是不区分面板的最简单回归，用来粗略看看结果
regress totalvalue_change_a rain $controls1
//具体用什么变量在另一个检验文件里咯
// 到时候记得改成面板回归的，然后加上各种调节变量等，看看文献怎么做我们就怎么来
//下一行的函数的意思是把自己的回归存好，最后在esttab里就可以给一个完整的大表了
estimates store m1
//理解为一个弱化版的描述性统计即可
summarize totalvalue_change_a rain $controls1
//下一行就是常见的多个回归放一起的汇总表
esttab m1, star(* 0.10 ** 0.05 *** 0.01) t(%9.2f) b(%9.3f) margin  legend label varlabels(_cons constant)  stats(N r2_a, fmt(0 3))

//是否需要时间固定效应回归呢？我们也是做检验先哈然后定
tab time,gen(d_time)
//reg totalvalue_change_a rain $controls1 d_time2-d_time57 i.provincecode
xtreg totalvalue_change_a rain $controls1,fe
xtreg totalvalue_change_a rain $controls1,re
xttest0
xtreg totalvalue_change_a rain $controls1,re
est store re
xtreg totalvalue_change_a rain $controls1,fe
est store fe
hausman fe re

//test d_time40 d_time41 d_time42 d_time43 d_time44 d_time45
areg totalvalue_change_a rain $controls1 i.time , absorb(code)
//到时候先根据检验看我们需要什么样的固定效应然后试情况定


