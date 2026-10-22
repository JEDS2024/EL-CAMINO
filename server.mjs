import {createServer} from 'node:http';
import {readFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {resolve,extname,sep} from 'node:path';
const root=fileURLToPath(new URL('.',import.meta.url));
const mime={'.html':'text/html; charset=utf-8','.css':'text/css; charset=utf-8','.js':'text/javascript; charset=utf-8'};
const server=createServer(async(req,res)=>{try{
 const pathname=decodeURIComponent(new URL(req.url,'http://localhost').pathname);
 const path=resolve(root,'.'+(pathname==='/'?'/index.html':pathname));
 if(!path.startsWith(root)||path.slice(root.length).split(sep).some(p=>p.startsWith('.'))||!mime[extname(path)]){res.writeHead(404);res.end('No encontrado');return;}
 const body=await readFile(path);res.writeHead(200,{'Content-Type':mime[extname(path)],'Cache-Control':'no-store'});res.end(body);
}catch{res.writeHead(404);res.end('No encontrado');}});
server.listen(Number(process.env.PORT)||5173,process.env.HOST||'127.0.0.1',()=>console.log(`LUMBRAL: http://${process.env.HOST||'127.0.0.1'}:${server.address().port}`));
