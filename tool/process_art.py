import sys, os
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage
U='/mnt/user-data/uploads/'
OUT='/home/claude/v-z-r/assets/img/'
os.makedirs(OUT,exist_ok=True)

def cutout(im, tol=18, shadow=False):
    a=np.asarray(im.convert('RGB')).astype(np.int16)
    h,w,_=a.shape
    # background colour from border median
    border=np.concatenate([a[0],a[-1],a[:,0],a[:,-1]])
    bg=np.median(border,axis=0)
    d=np.abs(a-bg).max(axis=2)
    cand=d<tol
    lab,n=ndimage.label(cand)
    edge=set(np.unique(np.concatenate([lab[0],lab[-1],lab[:,0],lab[:,-1]])))-{0}
    bgmask=np.isin(lab,list(edge))
    # also remove large enclosed near-white regions? no (keeps white parts)
    if shadow:
        lum=a.mean(axis=2); chroma=a.max(axis=2)-a.min(axis=2)
        sh=(chroma<16)&(lum>170)
        lab2,_=ndimage.label(sh|bgmask)
        keep=set(np.unique(lab2[bgmask]))-{0}
        shm=np.isin(lab2,list(keep))&~bgmask
        bgmask=bgmask|shm
        sizes=ndimage.sum(cand,lab,range(n+1))
        big=[i for i in range(1,n+1) if sizes[i]>300]
        bgmask=bgmask|np.isin(lab,big)
    alpha=np.where(bgmask,0,255).astype(np.uint8)
    # soft edge: pixels near boundary get alpha by distance from bg colour
    obj=~bgmask
    ring=obj & ndimage.binary_dilation(bgmask,iterations=2)
    soft=np.clip((d-4)/(tol*2.2),0,1)*255
    alpha=np.where(ring,np.minimum(alpha,soft.astype(np.uint8)),alpha)
    # remove the faint drop shadow: shadow pixels (low sat, slightly dark) connected to bg kept as is
    am=Image.fromarray(alpha).filter(ImageFilter.GaussianBlur(0.7))
    out=im.convert('RGB').copy(); out.putalpha(am)
    # de-fringe: unmultiply white
    o=np.asarray(out).astype(np.float32)
    al=o[...,3:4]/255
    rgb=o[...,:3]
    fixed=np.where(al>0.02,(rgb-bg*(1-al))/np.maximum(al,0.02),rgb)
    o[...,:3]=np.clip(fixed,0,255)
    return Image.fromarray(o.astype(np.uint8),'RGBA')

def crop(im,pad=6):
    bb=im.getchannel('A').point(lambda v:255 if v>20 else 0).getbbox()
    if not bb: return im
    l,t,r,b=bb
    return im.crop((max(0,l-pad),max(0,t-pad),min(im.width,r+pad),min(im.height,b+pad)))

def fit(im,maxw,maxh):
    im=im.copy(); im.thumbnail((maxw,maxh),Image.LANCZOS); return im

def save(im,name,q=82):
    im.save(OUT+name+'.webp','WEBP',quality=q,method=6)
    print(name,im.size,os.path.getsize(OUT+name+'.webp')//1024,'KB')

def bgimg(f,name):
    im=Image.open(U+f).convert('RGB').resize((720,1290),Image.LANCZOS); save(im,name,80)

def sprite(f,name,mw=640,mh=640,tol=18):
    save(fit(crop(cutout(Image.open(U+f),tol)),mw,mh),name)

def grid(f,names,cols,rows,mw,mh,area=None,tol=18,shadow=False):
    im=cutout(Image.open(U+f),tol,shadow)
    W,H=im.size
    x0,y0,x1,y1=area or (0,0,W,H)
    cw=(x1-x0)/cols; ch=(y1-y0)/rows
    for i,n in enumerate(names):
        if n is None: continue
        c,r=i%cols,i//cols
        cell=im.crop((int(x0+c*cw),int(y0+r*ch),int(x0+(c+1)*cw),int(y0+(r+1)*ch)))
        save(fit(crop(cell),mw,mh),n)

backs={'71b7a4e1':'bolge_kelime','c68240e1':'ada_harita','1ff37c23':'bolge_liman','fd002a6d':'bolge_bulut',
 'ea44e6d5':'bolge_sayi','8bc0e38d':'bolge_hece','32d460c0':'kilit_benzin','dc1c60af':'kilit_gece',
 'b9c476f7':'garaj_gece','78aea04e':'garaj_gunduz','5a4f4da1':'ana_ekran'}
cars={'ea3ec816':0,'6fd7377c':1,'bb790203':2,'4d21f377':3,'d767bee9':4,'fc74c8e6':5,'eb0c62ba':6,'77177f51':7,'c029ec0b':8,'6a3bdc3b':9,'ab6ed715':10}
spr={'1295929b':'k_robot','c82d2694':'k_papagan','935b3022':'k_surucu','bea13247':'k_tozbulut','4f33e531':'k_baykus','94a04984':'k_tamirci',
     '6e2e8497':'m_kitap','915098bd':'m_macera','26cc0b70':'m_yaris','b8d03bf4':'m_garaj','1a220c40':'bitis_taki'}
which=sys.argv[1] if len(sys.argv)>1 else 'all'
for f in os.listdir(U):
    k=f[:8]
    if which in('all','bg') and k in backs: bgimg(f,backs[k])
    if which in('all','car') and k in cars: sprite(f,'arac_%d'%cars[k],560,440)
    if which in('all','spr') and k in spr: sprite(f,spr[k],600,640)
    if which in('all','sheet'):
        if k=='1c9698bd': grid(f,['k_tozbulut_uzgun','k_tozbulut_gul','k_tozbulut_selam','k_tozbulut_anlat'],4,1,400,560)
        if k=='cf2198c1': grid(f,['k_baykus_saskin','k_baykus_okur','k_baykus_gosterir','k_baykus_uyur'],4,1,400,560)
        if k=='9b90f4ff': grid(f,['k_tamirci_iyi','k_tamirci_dusun','k_tamirci_saskin','k_tamirci_sevin'],4,1,400,560)
        if k=='06fb4053': grid(f,['i_yildiz','i_kalp','i_kupa','i_jeton','i_benzin','i_kilit'],3,2,200,200,area=(0,0,2048,1300))
        if k=='2ce0b3c6': grid(f,['d_agac','d_cam','d_pembe','d_cali','d_meyve','d_lale','d_cit','d_saman','d_tas'],3,3,300,300,shadow=True)
        if k=='7a6590d2': save(Image.open(U+f).convert('RGB').resize((512,512),Image.LANCZOS),'doku_cimen',78)
    if which in('all','pod') and k=='f77f9526': save(Image.open(U+f).convert('RGB').resize((720,720),Image.LANCZOS),'sonuc_kursu',80)
