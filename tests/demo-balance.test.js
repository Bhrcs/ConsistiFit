const assert = require('assert');

// Hidden CI guardrails for the consistency-first economy. These are not exposed as a developer mode in the app.
const RANKS=[['Iron III',0],['Iron II',50],['Iron I',100],['Bronze III',200],['Bronze II',350],['Bronze I',500],['Silver III',700],['Silver II',900],['Silver I',1100],['Gold III',1350],['Gold II',1550],['Gold I',1750],['Platinum III',1900],['Platinum II',2100],['Platinum I',2300],['Diamond III',2600],['Diamond II',3000],['Diamond I',3600],['Master',4500],['Grandmaster',6000]];
function rankAt(rp){let current=RANKS[0];for(const r of RANKS){if(rp<r[1])break;current=r;}return current[0];}

// A complete training day is 70 RP. A complete planned recovery day is 60 RP.
// The 10 RP gap preserves a small training-frequency difference without making high-frequency plans dominate rank.
function perfectWeek(trainingDays=3){return trainingDays*70+(7-trainingDays)*60;}
function projection(weeks,adherence,trainingDays=3){return Math.round(perfectWeek(trainingDays)*weeks*adherence);}
function weeklyXp(trainingDays=3){return trainingDays*400+(7-trainingDays)*290;}
function weeklyCoins(trainingDays=3){return trainingDays*175+(7-trainingDays)*130;}

const perfect4=projection(4,1);
const perfect12=projection(12,1);
const perfect14=projection(14,1);
const steady12=projection(12,.75);
const casual12=projection(12,.55);

assert(perfect4 >= 1750 && perfect4 < 1900, `4 perfect weeks should land around Gold I, got ${perfect4} RP / ${rankAt(perfect4)}`);
assert(perfect12 >= 4500 && perfect12 < 6000, `12 perfect weeks should reach Master but not Grandmaster, got ${perfect12}`);
assert(perfect14 >= 6000, `roughly 14 perfect weeks should be enough to enter Grandmaster, got ${perfect14}`);
assert(steady12 < 4500, `75% adherence should remain below Master at 12 weeks, got ${steady12}`);
assert(casual12 < 3000, `55% adherence should remain below Diamond II at 12 weeks, got ${casual12}`);

const rp2=perfectWeek(2),rp6=perfectWeek(6);
assert(rp6/rp2 <= 1.10, `2-day and 6-day plans should stay within 10% weekly RP, got ${rp2} vs ${rp6}`);
assert(weeklyXp(6)/weeklyXp(2) <= 1.25, 'account XP should not heavily favor high-frequency plans');
assert(weeklyCoins(6)/weeklyCoins(2) <= 1.20, 'Coin income should not heavily favor high-frequency plans');
assert(rp2 >= 400, 'low-frequency plans must still progress meaningfully through planned consistency');

console.log('Consistency economy guardrails passed', {
  rpPerWeek:{twoDay:rp2,threeDay:perfectWeek(3),sixDay:rp6},
  perfect4,perfect12,perfect14,steady12,casual12,
  ranks:{perfect4:rankAt(perfect4),perfect12:rankAt(perfect12),steady12:rankAt(steady12),casual12:rankAt(casual12)}
});
