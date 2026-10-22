export const obstacles = [
  {x:38,y:53,w:105,h:66}, {x:194,y:40,w:94,h:68},
  {x:43,y:164,w:44,h:30}, {x:414,y:0,w:66,h:320},
];
export const people = [
  {id:'miriam',name:'Miriam · habitante de la aldea',x:161,y:179,color:'#9c6681'},
  {id:'neighbor',name:'Habitante de la aldea',x:295,y:256,color:'#637e8e'},
  {id:'jesus',name:'Jesús',x:358,y:151,color:'#eee6c9'},
];
export const targets = [...people, {id:'basket',x:105,y:261}, {id:'path',x:351,y:40}];
export const stages = ['meet','collect','deliver','jesus','follow','complete'];
export const objectives = {
  meet:'Conoce a Miriam, junto al pozo.', collect:'Busca la cesta junto al olivo del sur.',
  deliver:'Lleva la cesta a Miriam.',jesus:'Encuentra a Jesús, cerca de la orilla.',
  follow:'Acércate al sendero del norte para partir.',complete:'Has dado tu primer paso. El camino continúa.',
};
export function createState(){return {stage:'meet',x:226,y:235};}
export function canStand(x,y){
  if(x<10||x>404||y<26||y>306)return false;
  return !obstacles.some(o=>x+7>o.x&&x-7<o.x+o.w&&y+3>o.y&&y-7<o.y+o.h);
}
export function move(s,dx,dy,dt){
  const length=Math.hypot(dx,dy);if(!length)return;
  const distance=73*Math.min(Math.max(dt,0),.04)/length;
  if(canStand(s.x+dx*distance,s.y))s.x+=dx*distance;
  if(canStand(s.x,s.y+dy*distance))s.y+=dy*distance;
}
export function nearest(s){return targets.filter(t=>t.id!=='basket'||!['deliver','jesus','follow','complete'].includes(s.stage)).map(t=>({...t,d:Math.hypot(s.x-t.x,s.y-t.y)})).filter(t=>t.d<30).sort((a,b)=>a.d-b.d)[0]??null;}
export function interact(s,id){
  const target=nearest(s);if(!target||target.id!==id||s.stage==='complete')return null;
  if(id==='miriam'){
    if(s.stage==='meet'){s.stage='collect';return {speaker:'Miriam',lines:['La mañana ha sido larga. Dejé mi cesta junto al olivo, al sur de la aldea.','¿Podrías traerla? Un poco de ayuda puede cambiar el día de alguien.']};}
    if(s.stage==='collect')return {speaker:'Miriam',lines:['La cesta está junto al olivo, al sur. Gracias por ayudarme.']};
    if(s.stage==='deliver'){s.stage='jesus';return {speaker:'Miriam',lines:['¡Mi cesta! Gracias por escuchar y detenerte a ayudar.','Jesús está cerca de la orilla. Puedes encontrarlo al este de la aldea.']};}
    return {speaker:'Miriam',lines:['Que tengas un buen camino. Gracias por tu ayuda.']};
  }
  if(id==='basket'){
    if(s.stage==='collect'){s.stage='deliver';return {speaker:'La cesta',lines:['Recoges la cesta con cuidado. Es hora de devolvérsela a Miriam.']};}
    return {speaker:'Una cesta',lines:['Una cesta descansa bajo el olivo. Tal vez alguien de la aldea la esté buscando.']};
  }
  if(id==='neighbor')return {speaker:'Habitante de la aldea',lines:['El camino bordea las casas y continúa hacia el norte.','Miriam está junto al pozo. Jesús se encuentra cerca de la orilla.']};
  if(id==='jesus'){
    if(s.stage==='jesus'){s.stage='follow';return {speaker:'El encuentro · narración',lines:['Te acercas a Jesús y escuchas. Frente a ti se abre un camino de aprendizaje, servicio y esperanza.','Decides acompañarlo. Dirígete al sendero del norte para comenzar el viaje.']};}
    return {speaker:'Junto a la orilla · narración',lines:[s.stage==='follow'?'El sendero del norte te espera. Da el primer paso.':'Ves a Jesús junto a la orilla. Antes de partir, conoce a los habitantes y ayuda a Miriam.']};
  }
  if(id==='path'){
    if(s.stage==='follow'){s.stage='complete';return {speaker:'El camino',lines:['Dejas atrás la aldea y comienzas a acompañar a Jesús.']};}
    return {speaker:'El sendero',lines:['Antes de partir, termina tus encuentros en la aldea.']};
  }
}
