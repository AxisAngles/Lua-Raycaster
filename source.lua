--By Trey Reynolds

--Doesn't support triangles and stuff, only blocks and spheres, lol. Kind of crappy.
--I don't know how good this is compared to other people's methods, but I like to think I can be pretty smart sometimes.
--Should be fast enough for most cases. See the format.txt file for how I do stuff.

--Basically, how you use it is you have an array of all your objects.
--Then you partition those objects and you get a partition from it.
--Then you can call one of the raycast functions, raycast,raycasttest,raycastall with the partition.

--RAYCASTING FUNCTIONS
local castfuncs={}

function castfuncs.block(g,ox,oy,oz,dx,dy,dz)
	local rx,ry,rz=g.px-ox,g.py-oy,g.pz-oz
	local xd=dx*g.xx+dy*g.xy+dz*g.xz
	local yd=dx*g.yx+dy*g.yy+dz*g.yz
	local zd=dx*g.zx+dy*g.zy+dz*g.zz
	local xr=rx*g.xx+ry*g.xy+rz*g.xz
	local yr=rx*g.yx+ry*g.yy+rz*g.yz
	local zr=rx*g.zx+ry*g.zy+rz*g.zz
	if 0<xd and g.sx<xr then
		local t=(xr-g.sx)/xd
		local a=t*yd-yr
		local b=t*zd-zr
		if a*a<=g.sy*g.sy and b*b<=g.sz*g.sz then
			return t,ox+t*dx,oy+t*dy,oz+t*dz,-g.xx,-g.xy,-g.xz
		end
	elseif xd<0 and xr<-g.sx then
		local t=(xr+g.sx)/xd
		local a=t*yd-yr
		local b=t*zd-zr
		if a*a<=g.sy*g.sy and b*b<=g.sz*g.sz then
			return t,ox+t*dx,oy+t*dy,oz+t*dz,g.xx,g.xy,g.xz
		end
	end
	if 0<yd and g.sy<yr then
		local t=(yr-g.sy)/yd
		local a=t*zd-zr
		local b=t*xd-xr
		if a*a<=g.sz*g.sz and b*b<=g.sx*g.sx then
			return t,ox+t*dx,oy+t*dy,oz+t*dz,-g.yx,-g.yy,-g.yz
		end
	elseif yd<0 and yr<-g.sy then
		local t=(yr+g.sy)/yd
		local a=t*zd-zr
		local b=t*xd-xr
		if a*a<=g.sz*g.sz and b*b<=g.sx*g.sx then
			return t,ox+t*dx,oy+t*dy,oz+t*dz,g.yx,g.yy,g.yz
		end
	end
	if 0<zd and g.sz<zr then
		local t=(zr-g.sz)/zd
		local a=t*xd-xr
		local b=t*yd-yr
		if a*a<=g.sx*g.sx and b*b<=g.sy*g.sy then
			return t,ox+t*dx,oy+t*dy,oz+t*dz,-g.zx,-g.zy,-g.zz
		end
	elseif zd<0 and zr<-g.sz then
		local t=(zr+g.sz)/zd
		local a=t*xd-xr
		local b=t*yd-yr
		if a*a<=g.sx*g.sx and b*b<=g.sy*g.sy then
			return t,ox+t*dx,oy+t*dy,oz+t*dz,g.zx,g.zy,g.zz
		end
	end
end

function castfuncs.sphere(g,ox,oy,oz,dx,dy,dz)
	local rx,ry,rz=g.px-ox,g.py-oy,g.pz-oz
	local rad=g.r
	local r2=rx*rx+ry*ry+rz*rz
	local rd=rx*dx+ry*dy+rz*dz
	local x2=rad*rad+rd*rd-r2--dist from center of sphere ^ 2.
	if 0<x2 then
		local t=rd-x2^0.5
		local ix,iy,iz=ox+t*dx,oy+t*dy,oz+t*dz
		return t,ix,iy,iz,(ix-g.px)/rad,(iy-g.py)/rad,(iz-g.pz)/rad
	end
end








--BOUNDINGSPHERE FUNCTIONS
local boundfuncs={}

function boundfuncs.block(g)
	return (g.sx*g.sx+g.sy*g.sy+g.sz*g.sz)^0.5,g.px,g.py,g.pz
end

function boundfuncs.wedge(g)
	return (g.sx*g.sx+g.sy*g.sy+g.sz*g.sz)^0.5,g.px,g.py,g.pz
end

function boundfuncs.cornerwedge(g)
	return (g.sx*g.sx+g.sy*g.sy+g.sz*g.sz)^0.5,g.px,g.py,g.pz
end

function boundfuncs.sphere(g)
	return g.r,g.px,g.py,g.pz
end

function boundfuncs.cylinder(g)
	return (g.r*g.r+g.h*g.h)^0.5,g.px,g.py,g.pz
end








--FILE WRITING FUNCTIONS
local newcanvas,savebmp do
	local char		=string.char
	local byte		=string.byte
	local sub		=string.sub
	local rep		=string.rep
	local concat	=table.concat
	local open		=io.open

	local function tobytes(n)
		local r0=n%256
		n=(n-r0)/256
		local r1=n%256
		n=(n-r1)/256
		local r2=n%256
		n=(n-r2)/256
		local r3=n%256
		return char(r0,r1,r2,r3)
	end

	function savebmp(self,path)
		path=path or self.path
		local h=self.h
		local w=self.w
		local excess=-3*w%4
		local bytes=h*(3*w+excess)
		local lineend=rep('\0',excess)
		local n=1
		local bmp={
			"BM"									--Header
			..tobytes(54+bytes)						--Total file size.
			.."\0\0\0\0\54\0\0\0\40\0\0\0"			--No clue
			..tobytes(w)..tobytes(h)				--Width by height
			.."\1\0\24\0\0\0\0\0"					--Defines 24 bit color
			..tobytes(bytes)						--Total pixel byte length
			.."\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"	--Space that we don't use
		}
		for i=1,h do
			local row=self[i]
			for j=1,w do
				local pixel=row[j]
				local r=255*pixel.r+0.5
				local g=255*pixel.g+0.5
				local b=255*pixel.b+0.5
				r=r-r%1
				g=g-g%1
				b=b-b%1
				n=n+1
				bmp[n]=char(
					b~=b and 0 or b<0 and 0 or 255<b and 255 or b,
					g~=g and 0 or g<0 and 0 or 255<g and 255 or g,
					r~=r and 0 or r<0 and 0 or 255<r and 255 or r
				)
			end
			n=n+1
			bmp[n]=lineend
		end
		local data=concat(bmp)
		if path then
			local file=open(path,"wb")
			file:write(data)
			file:close()
		end
		return data
	end

	function newcanvas(w,h,r,g,b)
		r=r or 1
		g=g or 1
		b=b or 1
		local newcanvas={
			w=w;
			h=h;
		}
		for i=1,h do
			local row={}
			for j=1,w do
				row[j]={r=r;g=g;b=b;}
			end
			newcanvas[i]=row
		end
		return newcanvas
	end
end








--PARTITIONING SYSTEM
local partition do
	local sort=table.sort

	local function sortpartitions(a,b)
		return a.r<b.r
	end

	--This is a greedy algorithm. Less greedy than
	--a really shitty algorithm, but greedy nonetheless
	--At least it's n^2 instead of n! for a perfect algorithm
	local function recursivepartition(pars)
		local newpars	={}
		local bestpars	={}
		local pared		={}
		for i=1,#pars do
			local pari=pars[i]
			local ir=pari.r
			local ix,iy,iz=pari.px,pari.py,pari.pz
			for j=i+1,#pars do
				local parj=pars[j]
				local jr=parj.r
				local jx,jy,jz=parj.px,parj.py,parj.pz
				local dx,dy,dz=jx-ix,jy-iy,jz-iz
				local d=(dx*dx+dy*dy+dz*dz)^0.5
				newpars[#newpars+1]=d+jr<ir and {i=i;j=j;r=ir;}
					or d+ir<jr and {i=i;j=j;r=jr;}
					or {i=i;j=j;r=(d+jr+ir)/2;}
			end
		end
		sort(newpars,sortpartitions)
		for i=1,#newpars do
			local newpar=newpars[i]
			if not pared[newpar.i] and not pared[newpar.j] then
				pared[newpar.i]=true
				pared[newpar.j]=true
				local pari=pars[newpar.i]
				local parj=pars[newpar.j]
				local ir=pari.r
				local jr=parj.r
				local ix,iy,iz=pari.px,pari.py,pari.pz
				local jx,jy,jz=parj.px,parj.py,parj.pz
				local dx,dy,dz=jx-ix,jy-iy,jz-iz
				local d=(dx*dx+dy*dy+dz*dz)^0.5
				local c=(jr-ir)/(2*d)+0.5
				bestpars[#bestpars+1]=d+jr<ir and {i=pari;j=parj;r=ir;px=ix;py=iy;pz=iz;}
					or d+ir<jr and {i=pari;j=parj;r=jr;px=jx;py=jy;pz=jz;}
					or {i=pari;j=parj;r=(d+jr+ir)/2;px=ix+c*dx;py=iy+c*dy;pz=iz+c*dz;}
			end
			newpars[i]=nil
		end
		for i=1,#pars do
			if not pared[i] then
				bestpars[#bestpars+1]=pars[i]
				break
			end
		end
		if #bestpars==0 then
			return bestpars
		elseif #bestpars==1 then
			return bestpars[1]
		else
			return recursivepartition(bestpars)
		end
	end

	function partition(geom)
		local pars={}
		for i=1,#geom do
			local g=geom[i]
			local r,px,py,pz=boundfuncs[g.type](g)
			pars[#pars+1]={g=g;px=px;py=py;pz=pz;r=r}
		end
		return recursivepartition(pars)
	end
end








--RAYCASTING SYSTEM
local raycast,raycasttest,raycastall do
	local sort=table.sort
	local inf=1/0

	local mem={}
	local defign={}

	local function sortdist(a,b)
		return a.d<b.d
	end

	function raycast(mainpar,ox,oy,oz,dx,dy,dz,d,ign)
		d=d or inf
		ign=ign or defign
		local hit,ix,iy,iz,nx,ny,nz
		local n,t=0,1
		mem[1]=mainpar
		while n<t do
			n=n+1
			local par=mem[n]
			local r=par.r
			local rx,ry,rz=par.px-ox,par.py-oy,par.pz-oz
			local rd=rx*dx+ry*dy+rz*dz
			local r2=rx*rx+ry*ry+rz*rz
			if (0<rd or r2<r*r) and r2<r*r+rd*rd and (rd<d or d*d+r2<r*r+2*rd*d) then
				if not par.g then
					t=t+1;mem[t]=par.i
					t=t+1;mem[t]=par.j
				elseif not (ign==par.g or ign[par.g]) then
					local mhit=par.g
					local md,mix,miy,miz,mnx,mny,mnz=castfuncs[mhit.type](mhit,ox,oy,oz,dx,dy,dz)
					if md and 0<md and md<d then
						hit,d,ix,iy,iz,nx,ny,nz=mhit,md,mix,miy,miz,mnx,mny,mnz
					end
				end
			end
		end
		if hit then
			return hit,d,ix,iy,iz,nx,ny,nz
		end
	end

	function raycasttest(mainpar,ox,oy,oz,dx,dy,dz,d,ign)
		d=d or inf
		ign=ign or defign
		local n,t=0,1
		mem[1]=mainpar
		while n<t do
			n=n+1
			local par=mem[n]
			local r=par.r
			local rx,ry,rz=par.px-ox,par.py-oy,par.pz-oz
			local rd=rx*dx+ry*dy+rz*dz
			local r2=rx*rx+ry*ry+rz*rz
			if (0<rd or r2<r*r) and r2<r*r+rd*rd and (rd<d or d*d+r2<r*r+2*rd*d) then
				if not par.g then
					t=t+1;mem[t]=par.i
					t=t+1;mem[t]=par.j
				elseif not (ign==par.g or ign[par.g]) then
					local mhit=par.g
					local md=castfuncs[mhit.type](mhit,ox,oy,oz,dx,dy,dz)
					if md and 0<md and md<d then
						return true
					end
				end
			end
		end
		return false
	end

	function raycastall(mainpar,ox,oy,oz,dx,dy,dz,d,ign)
		d=d or inf
		ign=ign or defign
		local n,t=0,1
		local ints,m={},0
		mem[1]=mainpar
		while n<t do
			n=n+1
			local par=mem[n]
			local r=par.r
			local rx,ry,rz=par.px-ox,par.py-oy,par.pz-oz
			local rd=rx*dx+ry*dy+rz*dz
			local r2=rx*rx+ry*ry+rz*rz
			if (0<rd or r2<r*r) and r2<r*r+rd*rd and (rd<d or d*d+r2<r*r+2*rd*d) then
				if not par.g then
					t=t+1;mem[t]=par.i
					t=t+1;mem[t]=par.j
				elseif not (ign==par.g or ign[par.g]) then
					local hit=par.g
					local md,ix,iy,iz,nx,ny,nz=castfuncs[hit.type](hit,ox,oy,oz,dx,dy,dz)
					if md and 0<md and md<d then
						m=m+1;ints[m]={hit=hit;d=md;ix=ix;iy=iy;iz=iz;nx=nx;ny=ny;nz=nz;}
					end
				end
			end
		end
		sort(ints,sortdist)
		return ints,m
	end
end
