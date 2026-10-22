import test from 'node:test';
import assert from 'node:assert/strict';
import {createState,move,canStand,interact,nearest} from '../src/engine.js';
function at(s,x,y,id){s.x=x;s.y=y;return interact(s,id);}
test('se completa únicamente la secuencia de servicio, encuentro y partida',()=>{
 const s=createState();assert.equal(at(s,351,44,'path').speaker,'El sendero');assert.equal(s.stage,'meet');
 at(s,358,160,'jesus');assert.equal(s.stage,'meet');
 at(s,105,270,'basket');assert.equal(s.stage,'meet');
 at(s,161,185,'miriam');assert.equal(s.stage,'collect');
 at(s,161,185,'miriam');assert.equal(s.stage,'collect');
 at(s,105,270,'basket');assert.equal(s.stage,'deliver');assert.notEqual(nearest(s)?.id,'basket');
 at(s,358,160,'jesus');assert.equal(s.stage,'deliver');
 at(s,161,185,'miriam');assert.equal(s.stage,'jesus');
 at(s,351,44,'path');assert.equal(s.stage,'jesus');
 at(s,358,160,'jesus');assert.equal(s.stage,'follow');
 at(s,351,44,'path');assert.equal(s.stage,'complete');
});
test('no se puede interactuar a distancia',()=>{const s=createState();assert.equal(interact(s,'miriam'),null);assert.equal(s.stage,'meet');});
test('casas, agua y límites bloquean el movimiento',()=>{
 assert.equal(canStand(70,80),false);assert.equal(canStand(420,200),false);assert.equal(canStand(-1,200),false);
 const s={...createState(),x:403,y:200};for(let i=0;i<200;i++)move(s,1,0,.016);assert.ok(s.x<=404);
 s.x=180;s.y=85;for(let i=0;i<200;i++)move(s,1,0,.016);assert.ok(s.x<=187);
});
test('movimiento diagonal normalizado y pausas sin saltos',()=>{
 const a=createState(),b=createState();move(a,1,0,.04);move(b,1,1,.04);
 assert.ok(Math.abs(Math.hypot(a.x-226,a.y-235)-Math.hypot(b.x-226,b.y-235))<.0001);
 const s=createState();move(s,1,0,100);assert.ok(s.x-226<=73*.04+.0001);
});
