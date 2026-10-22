import {createState,people,nearest,interact,move,stages,objectives} from './engine.js';
const $=id=>document.getElementById(id),canvas=$('world'),ctx=canvas.getContext('2d');
let state=createState(),started=false,dialog=null,line=0,last=0,time=0,uiSignature='';
const keys=new Set(),touches=new Map();
const colors={grass:'#98a66b',sand:'#d8bd82',shadow:'#53664d',ink:'#314639'};
function rect(x,y,w,h,c){ctx.fillStyle=c;ctx.fillRect(Math.round(x),Math.round(y),w,h);}
function label(text,x,y,color='#fff0ce'){ctx.font='8px monospace';ctx.textAlign='center';ctx.fillStyle='#16392acb';ctx.fillRect(x-text.length*2.5-4,y-8,text.length*5+8,12);ctx.fillStyle=color;ctx.fillText(text,x,y);}
function house(x,y,w,h){rect(x+4,y+6,w,h,'#6e7950');rect(x,y,w,h,'#c4a474');rect(x+4,y+6,w-8,h-6,'#dfc394');rect(x-5,y-8,w+10,15,'#9d6649');rect(x-1,y-12,w+2,6,'#ba8055');for(let i=0;i<w;i+=12)rect(x+i,y-6,2,12,'#855b46');rect(x+w/2-9,y+h-24,18,24,'#624e3c');rect(x+w/2-7,y+h-22,14,22,'#433f31');rect(x+11,y+18,14,15,'#816e4b');rect(x+13,y+20,10,11,'#344b43');rect(x+w-25,y+18,12,15,'#816e4b');rect(x+w-23,y+20,8,11,'#344b43');rect(x+3,y+h-3,w-6,3,'#af8c60');}
function tree(x,y){rect(x-3,y-8,6,21,'#716247');rect(x-1,y-5,3,17,'#a38c5d');rect(x-14,y-30,28,21,'#4d674b');rect(x-21,y-22,40,13,'#4d674b');rect(x-16,y-31,26,14,'#698052');rect(x-12,y-35,21,15,'#7f925d');rect(x-19,y-20,12,7,'#829361');for(let i=0;i<5;i++)rect(x-13+i*6,y-22+(i%2)*7,2,2,'#b6b478');}
function person(p,player=false){const x=Math.round(p.x),y=Math.round(p.y);const stride=player&&(keys.size||touches.size)&&!dialog?Math.sin(time*12)*2:0;rect(x-7,y+1,15,4,'#48644877');rect(x-5,y-11,10,13,p.color||'#467f82');rect(x-7,y-9,3,9,'#bf936c');rect(x+5,y-9,3,9,'#bf936c');rect(x-3,y-3,2,6+stride,'#473f32');rect(x+2,y-3,2,6-stride,'#473f32');rect(x-4,y-21,8,10,'#d9aa7b');rect(x-5,y-23,10,5,'#594534');rect(x-5,y-20,2,6,'#594534');if(p.id==='jesus'){rect(x+3,y-20,2,9,'#594534');rect(x-2,y-13,5,2,'#72513b');rect(x+1,y-10,3,10,'#b58c64');}else if(player){rect(x-3,y-11,2,12,'#c8bd8b');rect(x-5,y-3,10,2,'#806b46');}else if(p.id==='miriam'){rect(x-5,y-23,10,4,'#dec1a2');rect(x-6,y-19,2,9,'#dec1a2');}}
function draw(){
 ctx.clearRect(0,0,480,320);rect(0,0,480,320,colors.grass);
 for(let i=0;i<210;i++){const x=(i*137+19)%414,y=(i*73+17)%320;rect(x,y,2,2,i%3?'#a8b477':'#82965f');if(i%8===0)rect(x+2,y-1,2,2,'#c3be7e');}
 rect(176,0,29,162,colors.sand);rect(125,124,266,36,colors.sand);rect(194,139,46,181,colors.sand);rect(90,231,228,35,colors.sand);rect(322,24,54,134,colors.sand);rect(206,176,164,28,colors.sand);rect(200,155,20,30,colors.sand);
 for(let i=0;i<95;i++){const x=(i*71)%390,y=(i*47)%320;if((x>194&&x<238)||(y>126&&y<158))rect(x,y,3,1,'#bda473');}
 rect(403,0,12,320,'#cebd87');rect(414,0,66,320,'#5e9fa1');rect(425,0,55,320,'#4c8d97');for(let i=0;i<38;i++){const y=(i*23+Math.floor(time*3))%320,x=419+(i*17)%57;rect(x,y,9+(i%3)*4,2,'#91bdb1');}
 house(38,53,105,66);house(194,40,94,68);
 rect(43,164,44,30,'#8a6f4d');rect(40,160,50,7,'#b18a57');for(let i=0;i<4;i++){rect(46+i*10,168,7,7,'#c7a66a');rect(47+i*10,178,5,5,'#9b7046');}
 tree(106,251);tree(18,145);tree(303,70);tree(388,263);tree(35,304);
 // Pozo y cántaros.
 rect(161,202,26,12,'#8e8665');rect(157,199,34,8,'#d0c298');rect(163,198,22,6,'#344c49');rect(158,187,3,14,'#7f6448');rect(186,187,3,14,'#7f6448');rect(156,183,35,5,'#a77f52');
 for(const [x,y] of [[151,119],[290,111],[371,194]]){rect(x,y,8,10,'#a96d4c');rect(x-1,y+2,10,5,'#be875b');rect(x+2,y-2,4,3,'#73543c');}
 // Barca junto a la orilla.
 rect(395,221,18,31,'#705a3e');rect(392,225,20,23,'#a57a4c');rect(398,229,10,15,'#604f3a');rect(402,217,2,38,'#cfb179');
 if(!['deliver','jesus','follow','complete'].includes(state.stage)){rect(99,255,13,9,'#a97842');rect(101,253,9,2,'#d5af6c');rect(100,257,11,2,'#d4a25c');rect(102,253,2,10,'#b88b51');}
 const guide={meet:'miriam',collect:'basket',deliver:'miriam',jesus:'jesus',follow:'path'}[state.stage];
 const all=[...people,{...state,id:'player'}].sort((a,b)=>a.y-b.y);all.forEach(p=>person(p,p.id==='player'));
 if(guide){const target=guide==='basket'?{x:105,y:261}:guide==='path'?{x:351,y:40}:people.find(p=>p.id===guide);const y=target.y-34+Math.sin(time*3)*2;rect(target.x-1,y,3,7,'#ffe2a1');rect(target.x-1,y+9,3,2,'#ffe2a1');}
 // Sendero hacia el siguiente capítulo.
 for(let i=0;i<3;i++){rect(343+i*3,23-i*3,3,2,'#806e4d');rect(352+i*3,17+i*3,3,2,'#806e4d');}
 const near=nearest(state);if(near&&started&&!dialog&&state.stage!=='complete')label(near.id==='basket'?'CESTA':near.id==='path'?'SENDERO':near.id==='miriam'?'MIRIAM':near.id==='jesus'?'JESÚS':'HABITANTE',near.x,near.y+17);
}
function refresh(){
 const signature=[state.stage,nearest(state)?.id,started,Boolean(dialog)].join('|');
 if(signature===uiSignature)return;uiSignature=signature;
 $('objective').textContent=objectives[state.stage];$('progress').textContent=`${Math.min(stages.indexOf(state.stage)+1,5)} / 5`;
 const near=nearest(state),active=started&&!dialog&&state.stage!=='complete';
 $('action').disabled=!active||!near;
 const verb=near?.id==='basket'?'Recoger':near?.id==='path'?'Partir':'Hablar';
 $('action').innerHTML=`${verb} <kbd>E</kbd>`;
 $('hint').replaceChildren();const message=document.createTextNode(near?`Cerca ${near.id==='path'?'del sendero':near.id==='basket'?'de la cesta':near.id==='jesus'?'de Jesús':near.id==='miriam'?'de Miriam':'de un habitante'}.`:'Explora a tu ritmo.');$('hint').append(message,document.createElement('br'));const help=document.createElement('span');help.textContent='WASD / flechas para caminar';$('hint').append(help);
}
function clearInput(){keys.clear();touches.clear();document.querySelectorAll('.pressed').forEach(b=>b.classList.remove('pressed'));}
function openDialogue(d){dialog=d;line=0;clearInput();$('dialog').hidden=false;showLine();$('next').focus();refresh();}
function showLine(){$('speaker').textContent=dialog.speaker;$('speech').textContent=dialog.lines[line];$('next').textContent=line===dialog.lines.length-1?'Seguir →':'Continuar →';}
function advance(){if(!dialog)return;if(++line<dialog.lines.length){showLine();return;}dialog=null;$('dialog').hidden=true;if(state.stage==='complete'){$('ending').hidden=false;$('replay').focus();}else canvas.focus({preventScroll:true});refresh();}
function action(){if(!started||dialog||state.stage==='complete')return;const t=nearest(state);if(t){const d=interact(state,t.id);if(d)openDialogue(d);}}
function reset(){clearInput();state=createState();started=false;dialog=null;$('intro').hidden=false;$('dialog').hidden=true;$('ending').hidden=true;$('start').focus({preventScroll:true});refresh();}
$('start').onclick=()=>{started=true;$('intro').hidden=true;clearInput();canvas.focus({preventScroll:true});refresh();};
$('next').onclick=advance;$('action').onclick=action;$('reset').onclick=reset;$('replay').onclick=reset;
const mappings={ArrowUp:'up',w:'up',ArrowDown:'down',s:'down',ArrowLeft:'left',a:'left',ArrowRight:'right',d:'right'};
window.addEventListener('keydown',e=>{if(e.target instanceof HTMLButtonElement)return;const direction=mappings[e.key]||mappings[e.key.toLowerCase()];if(direction){e.preventDefault();if(started&&!dialog)keys.add(direction);}if(['e','E',' '].includes(e.key)){e.preventDefault();if(e.repeat)return;if(dialog)advance();else action();}});
window.addEventListener('keyup',e=>{const d=mappings[e.key]||mappings[e.key.toLowerCase()];if(d)keys.delete(d);});
for(const b of document.querySelectorAll('[data-move]')){
 b.addEventListener('pointerdown',e=>{e.preventDefault();b.setPointerCapture(e.pointerId);if(started&&!dialog){touches.set(e.pointerId,b.dataset.move);b.classList.add('pressed');}});
 const release=e=>{touches.delete(e.pointerId);b.classList.remove('pressed');};b.addEventListener('pointerup',release);b.addEventListener('pointercancel',release);b.addEventListener('lostpointercapture',release);
}
window.addEventListener('blur',clearInput);document.addEventListener('visibilitychange',clearInput);
// Mantener el foco dentro de las escenas superpuestas al navegar con teclado.
window.addEventListener('keydown',e=>{if(e.key!=='Tab')return;const modal=!$('intro').hidden?$('start'):dialog?$('next'):!$('ending').hidden?$('replay'):null;if(modal){e.preventDefault();modal.focus({preventScroll:true});}});
function frame(now){const dt=last?(now-last)/1000:0;last=now;time=now/1000;if(started&&!dialog&&state.stage!=='complete'){const held=new Set([...keys,...touches.values()]);move(state,Number(held.has('right'))-Number(held.has('left')),Number(held.has('down'))-Number(held.has('up')),dt);}draw();refresh();requestAnimationFrame(frame);}
refresh();requestAnimationFrame(frame);
