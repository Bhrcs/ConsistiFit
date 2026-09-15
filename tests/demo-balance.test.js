const assert = require('assert');

const RANKS=[['Iron III',0],['Iron II',50],['Iron I',100],['Bronze III',200],['Bronze II',350],['Bronze I',500],['Silver III',700],['Silver II',900],['Silver I',1100],['Gold III',1350],['Gold II',1550],['Gold I',1750],['Platinum III',1900],['Platinum II',2100],['Platinum I',2300],['Diamond III',2600],['Diamond II',3000],['Diamond I',3600],['Master',4500],['Grandmaster',6000]];
function rankAt(rp){let current=RANKS[0];for(const r of RANKS){if(rp<r[1])break;current=r;}return current[0];}
function perfectWeek(trainingDays=3){return trainingDays*70+(7-trainingDays)*45;}
function projection(weeks,adherence,trainingDays=3){return Math.round(perfectWeek(trainingDays)*weeks*adherence);}

const perfect4=projection(4,1);
const perfect12=projection(12,1);
const perfect16=projection(16,1);
const steady12=projection(12,.75);
const casual12=projection(12,.55);

assert(perfect4 >= 1350 && perfect4 < 1900, `4 perfect weeks should land around Gold, got ${perfect4} RP / ${rankAt(perfect4)}`);
assert(perfect12 >= 4500 && perfect12 < 6000, `12 perfect weeks should reach Master but not Grandmaster, got ${perfect12}`);
assert(perfect16 >= 6000, `roughly four perfect months should be enough to enter Grandmaster, got ${perfect16}`);
assert(steady12 < 4500, `75% adherence should remain below Master at 12 weeks, got ${steady12}`);
assert(casual12 < 3000, `55% adherence should remain below Diamond II at 12 weeks, got ${casual12}`);
assert(perfectWeek(2) < perfectWeek(6), 'more scheduled training days may progress slightly faster, but recovery still contributes');
assert(perfectWeek(2) >= 350, 'low-frequency plans must still progress through consistency');

console.log('Balance simulation passed', {perfect4,perfect12,perfect16,steady12,casual12,ranks:{perfect4:rankAt(perfect4),perfect12:rankAt(perfect12),steady12:rankAt(steady12),casual12:rankAt(casual12)}});
