; docformat = 'rst'
;
;+
;
; This function initializes the fitting parameters for F05189-2524,
; 2011 GMOS data.
;
; :Categories:
;    IFSF
;
; :Returns:
;    A structure with tags specified in INITTAGS.txt.
;
; :Params:
; 
; :Keywords:
;    initmaps: out, optional, type=structure
;      Parameters for map making.
;    initnad: out, optional, type=structure
;      Parameters for NaD fitting.
; 
; :Author:
;    David S. N. Rupke::
;      Rhodes College
;      Department of Physics
;      2000 N. Parkway
;      Memphis, TN 38104
;      drupke@gmail.com
;
; :History:
;    ChangeHistory::
;      2013sep, DSNR, complete re-write
;      2013nov25, DSNR, renamed, added copyright and license; moved
;                       description of tags to INITTAGS.txt file.
;      2013nov26, DSNR, changed line arrays to hashes to prevent
;                       bookkeeping errors
;      2013dec10, DSNR, testing and bug fixes
;      2013dec17, DSNR, renamed variables dx, dy, cx, cy;
;                       moved from unordered to ordered hashes; 
;                       turn hashes into structures before passing to IFSF
;      2013jan13, DSNR, updated to pass hashes for many parameters into IFSF, 
;                       instead of structures
;      2014jan16, DSNR, fixed one wrong wavelength label
;      2014feb26, DSNR, replaced ordered hashes with hashes
;      2014feb27, DSNR, added zsys_gas, platescale, specres
;      2014apr21, DSNR, added arguments for line ratio maps / VO plots
;      2014may23, DSNR, added arguments for plotting continuum images;
;                       changed way that map making and NaD parameters are 
;                       treated
;    
; :Copyright:
;    Copyright (C) 2013-2014 David S. N. Rupke
;
;    This program is free software: you can redistribute it and/or
;    modify it under the terms of the GNU General Public License as
;    published by the Free Software Foundation, either version 3 of
;    the License or any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;    General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program.  If not, see
;    http://www.gnu.org/licenses/.
;
;-
function ifsf_f05189,initmaps=initmaps,initnad=initnad

  bad=1d99

  gal = 'f05189'
  bin = 2d
  ncols = 28
  nrows = 27
  centcol = 14
  centrow = 14
  outstr = 'rb'+string(bin,format='(I0)')

; distance from central pixel
  x_pix = rebin(indgen(ncols)+1,ncols,nrows)
  y_pix = rebin(transpose(indgen(nrows)+1),ncols,nrows)
  rad_pix = sqrt((double(x_pix-centcol))^2d + (double(y_pix-centrow))^2d)

; Regions for setting components
  inuc0  = where(rad_pix le 3d,ctnuc0)
  inuc1  = where(rad_pix gt 3d AND rad_pix le 6d,ctnuc1)
  idisk0 = where(rad_pix gt 8d,ctdisk0)
  iedge0 = where(rad_pix ge 12d,ctedge0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Required pars
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Input file
  infile='/Users/drupke/ifs/gmos/cubes/'+gal+'/'+gal+outstr+'.fits'
  if ~ file_test(infile) then begin
     print,"ERROR: Data cube not found."
     return,0
  endif

; Lines to fit.
  lines = ['Halpha','Hbeta','HeI6678','HeI7065','HeII4686',$
           '[OI]6300','[OI]6364','[OIII]4959','[OIII]5007',$
           '[NI]5198','[NI]5200','[NII]6548','[NII]6583',$
           '[SII]6716','[SII]6731','[FeVII]5159','[FeVII]5721',$
           '[FeVII]6087','[FeX]6375']
  nlines = n_elements(lines)

; Max no. of components.
  maxncomp = 3

; Initialize line ties, n_comps, z_inits, and sig_inits.
  linetie = hash(lines,'Halpha')
  ncomp = hash(lines)
  zinit_gas = hash(lines)
  siginit_gas = hash(lines)
; note that siginit_gas is technically optional, put here for convenience
  foreach i,lines do begin
     ncomp[i] = dblarr(ncols,nrows)+maxncomp
     zinit_gas[i] = dblarr(ncols,nrows,maxncomp) + 0.0425d
     siginit_gas[i] = dblarr(maxncomp) + 150d
  endforeach
  zinit_stars=dblarr(ncols,nrows) + 0.043d
; iron lines
  tmplines = ['[FeVII]5159','[FeVII]5721','[FeVII]6087','[FeX]6375']
  foreach i,tmplines do begin
     linetie[i] = '[FeVII]6087'
     ncomp[i,*,*] = 1
     zinit_gas[i,*,*,0] = 0.041d
     siginit_gas[i,0] = 1000d
;     if ctnuc0 gt 0 then for j=0,ctnuc0-1 do begin
;        ncomp[i,x_pix[inuc0[j]]-1,y_pix[inuc0[j]]-1] = 2
;        zinit_gas[i,x_pix[inuc0[j]]-1,y_pix[inuc0[j]]-1,1] = 0.038d
;     endfor
     if ctedge0 gt 0 then for j=0,ctedge0-1 do $
        ncomp[i,x_pix[iedge0[j]]-1,y_pix[iedge0[j]]-1] = 0
  endforeach
; HeII line
  tmplines = ['HeII4686']
  foreach i,tmplines do begin
     linetie[i] = 'HeII4686'
     ncomp[i,*,*] = 1
     zinit_gas[i,*,*,0] = 0.041d
     if ctnuc0 gt 0 then for j=0,ctnuc0-1 do begin
        ncomp[i,x_pix[inuc0[j]]-1,y_pix[inuc0[j]]-1] = 2
        zinit_gas[i,x_pix[inuc0[j]]-1,y_pix[inuc0[j]]-1,1] = 0.039d
        siginit_gas[i,1] = 1000d
     endfor
;     if ctnuc1 gt 0 then for j=0,ctnuc1-1 do $
;       ncomp[i,x_pix[inuc1[j]]-1,y_pix[inuc1[j]]-1] = 1
;     if ctedge0 gt 0 then for j=0,ctedge0-1 do $
;        ncomp[i,x_pix[iedge0[j]]-1,y_pix[iedge0[j]]-1] = 0
  endforeach
; HeI lines
  tmplines = ['HeI6678','HeI7065']
  foreach i,tmplines do begin
     linetie[i] = 'HeI6678'
     ncomp[i,*,*] = 0
     if ctnuc0 gt 0 then for j=0,ctnuc0-1 do begin
        ncomp[i,x_pix[inuc0[j]]-1,y_pix[inuc0[j]]-1] = 1
        siginit_gas[i,0] = 500d
     endfor
  endforeach
; [OIII] lines
  tmplines = ['[OIII]4959','[OIII]5007']
  foreach i,tmplines do begin
    ncomp[i,*,*] = 2
    linetie[i] = '[OIII]5007'
    zinit_gas[i,*,*,0] = 0.041d
    zinit_gas[i,*,*,1] = 0.039d
    siginit_gas[i,1] = 1000d
  endforeach
; Balmer lines, low-ion. colliosional lines
  tmplines = ['Halpha','Hbeta',$
              '[NII]6548','[NII]6583',$
              '[SII]6716','[SII]6731']
  foreach i,tmplines do begin
     zinit_gas[i,*,*,1] = 0.041d
     zinit_gas[i,*,*,2] = 0.039d
     siginit_gas[i,2] = 1000d
;     if ctedge0 gt 0 then for j=0,ctedge0-1 do $
;        ncomp[i,x_pix[iedge0[j]]-1,y_pix[iedge0[j]]-1] = 1
     if ctdisk0 gt 0 then for j=0,ctdisk0-1 do $
        ncomp[i,x_pix[idisk0[j]]-1,y_pix[idisk0[j]]-1] = 2
  endforeach
;; Note that if we want to allow Hbeta to vary independently of Halpha, we also
;; have to turn off the line ratio constraint in IFSF_GMOS.
;; Hbeta
;  tmplines = ['Hbeta']
;  foreach i,tmplines do begin
;     linetie[i] = 'Hbeta'
;     zinit_gas[i,*,*,1] = 0.041d
;     zinit_gas[i,*,*,2] = 0.039d
;     siginit_gas[i,2] = 1000d
;     if ctedge0 gt 0 then for j=0,ctedge0-1 do $
;        ncomp[i,x_pix[iedge0[j]]-1,y_pix[iedge0[j]]-1] = 1
;     if ctdisk0 gt 0 then for j=0,ctdisk0-1 do $
;        ncomp[i,x_pix[idisk0[j]]-1,y_pix[idisk0[j]]-1] = 2
;  endforeach
; [OI] lines
  tmplines = ['[OI]6300','[OI]6364']
  foreach i,tmplines do begin
     linetie[i] = '[OI]6300'
     ncomp[i,*,*] = 2
     zinit_gas[i,*,*,1] = 0.041d
     if ctdisk0 gt 0 then for j=0,ctdisk0-1 do $
        ncomp[i,x_pix[idisk0[j]]-1,y_pix[idisk0[j]]-1] = 1
  endforeach
; [NI] lines
  tmplines = ['[NI]5198','[NI]5200']
  foreach i,tmplines do begin
     linetie[i] = '[NI]5200'
     ncomp[i,*,*] = 1
;     if ctedge0 gt 0 then for j=0,ctedge0-1 do $
;        ncomp[i,x_pix[iedge0[j]]-1,y_pix[iedge0[j]]-1] = 0
  endforeach

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Optional pars
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Parameters for continuum fit
  tweakcntfit = dblarr(ncols,nrows,3,10)
; Default fitting order
  tweakcntfit[*,*,2,*] = 2
; Number of wavelength regions to re-fit
  nregions = 7
; Lower wavelength for re-fit
  tweakcntfit[*,*,0,0:nregions-1] = $
     rebin(reform([4950,5250,5850,6200,6500,6725,6925],1,1,1,nregions),$
           ncols,nrows,1,nregions)
; Upper wavelength for re-fit
  tweakcntfit[*,*,1,0:nregions-1] = $
     rebin(reform([5100,5450,6000,6400,6700,6925,7100],1,1,1,nregions),$
           ncols,nrows,1,nregions)
; Order for re-fit
  tweakcntfit[*,*,2,0:nregions-1] = $
     rebin(reform([2,2,2,2,2,1,1],1,1,1,nregions),$
           ncols,nrows,1,nregions)

; Parameters for emission line plotting
  linoth = strarr(2,6)
  linoth[0,2] = '[OIII]4959'
  linoth[*,3] = ['[OI]6364','[FeX]6375']
  linoth[*,4] = ['[NII]6548','[NII]6583']
  linoth[*,5] = ['HeI6678','[SII]6716']
  argspltlin1 = {nx: 3, ny: 2,$
                 label: ['HeII4686','Hbeta','[OIII]5007',$
                         '[OI]6300','Halpha','[SII]6731'],$
                 wave: [4686,4861,5007,6300,6563,6731],$
                 off: [[-120,90],[-80,50],[-130,50],$
                       [-80,120],[-95,70],[-95,50]],$
                 linoth: linoth}
  linoth = strarr(3,6)
  linoth[*,0] = ['[NI]5198','[NI]5200','[FeVII]5159']
  argspltlin2 = {nx: 3, ny: 2,$
                 label: ['[FeVII]5159','[FeVII]5721','[FeVII]6087',$
                         'HeI7065','',''],$
                 wave: [5159,5721,6087,7065,0,0],$
                 off: [[-120,90],[-120,90],[-120,90],$
                       [-90,80],[-90,80],[-90,80]],$
                 linoth: linoth}

; Velocity dispersion limits and fixed values
  siglim_gas = [299792d/3000d/2.35d,2000d]
  sigfix=hash()
  sigfix['[FeVII]6087'] = 725d
  lratfix=hash()
  lratfix['[NI]5200/5198'] = [1.5d]
  lratfix['[NII]6583/Ha'] = [bad,1.80,2.14]
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Output structure
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  init = {$
; Required pars
         fcninitpar: 'ifsf_gmos',$
         fitran: [4600,7100],$
         infile: infile,$
         label: gal,$
         lines: lines,$
         linetie: linetie,$
         mapdir: '/Users/drupke/ifs/gmos/maps/'+gal+'/'+outstr+'/',$
         maxncomp: maxncomp,$
         ncomp: ncomp,$
         outdir: '/Users/drupke/specfits/gmos/'+gal+'/'+outstr+'/',$
         platescale: 0.2d,$
         specres: 1.6d,$
         positionangle: 0d,$
         zinit_stars: zinit_stars,$
         zinit_gas: zinit_gas,$
         zsys_gas: 0.04275d,$
; Optional pars
;         argscheckcomp: {sigcut: 2},$
         argsinitpar: {siglim: siglim_gas,$
                       sigfix: sigfix,$
                       lratfix: lratfix},$
         argspltlin1: argspltlin1,$
         argspltlin2: argspltlin2,$
         donad: 1,$
         fcncheckcomp: 'ifsf_checkcomp',$
         fcncontfit: 'ppxf',$
         mapcent: [centcol,centrow],$
         nomaskran: [5075,5100],$
         siglim_gas: siglim_gas,$
         siginit_gas: siginit_gas,$
         siginit_stars: 100d,$
;        first # is max sig, second is step size
         startempfile: '/Users/drupke/Documents/stellar_models/'+$
         'gonzalezdelgado/SSPGeneva_z020.sav', $
         tweakcntfit: tweakcntfit $
        }

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Arguments for maps
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
   if keyword_set(initmaps) then begin
      argslinratmaps = hash()
      argslinratmaps['lrat1'] = [['1_n2ha','2_n2ha','3_n2ha'],$
                                 ['1_o3hb','2_o3hb','3_o3hb'],$
                                 ['1_n2ha_vs_o3hb','2_n2ha_vs_o3hb',$
                                  '3_n2ha_vs_o3hb']]
      argslinratmaps['ebv'] = ['1_ebv','2_ebv','3_ebv']

      initmaps = {$
                  center_axes: [centcol,centrow],$
                  center_nuclei: [centcol,centrow],$
                  rangefile: '/Users/drupke/ifs/gmos/maps/'+$
                             'f05189/rb2/ranges.txt',$
                  argslinratmaps: argslinratmaps,$
;                  applyebv: [1,0,0],$
                  col: {sumrange: [4900,5000,6650,6750],$
                        scllim: [-0.1,0.2],$
                        stretch: 1},$
                  ct: {sumrange: [5600,6400],$
                       scllim: [0,1],$
                       stretch: 1},$
                  hst: {refcoords: [3261,2708],$
                        subim_sm: 7d,$
                        subim_big: 25d,$
                        smoothfwhm: 12},$
                  hstbl: {file: '/Users/drupke/ifs/gmos/ancillary/hst/'+$
                                'f05189/f05189_acs_435w.fits',$
                          scllim: [0.01,100],$
                          sclargs: {beta: 0.05}},$
                  hstblsm: {scllim: [0,10],$
                            sclargs: {beta: 0.5},$
                            stretch: 5},$
                  hstrd: {file: '/Users/drupke/ifs/gmos/ancillary/hst/'+$
                                'f05189/f05189_acs_814w.fits',$
                          scllim: [0.01,100],$
                          sclargs: {beta: 0.05}},$
                  hstrdsm: {scllim: [0,20],$
                            sclargs: {beta: 0.5},$
                            stretch: 5}, $
                  hstcol: {scllim: [0,1],$
                           stretch: 1,$
                           sclargs: {dumy: 1}},$
                  hstcolsm: {scllim: [0.3,0.8],$
                             stretch: 1,$
                             sclargs: {dumy: 1}}$
                 }
   endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Parameters for NaD + HeI 5876 fit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   if keyword_set(initnad) then begin
  
      normnadlo = [6040,6090]
      normnadhi = [6170,6220]
      pltnormnad = [6040,6220]
      nad_maxncomp = 2

;     Initialize n_comps, z_inits, and sig_inits.
;     Use 1 HeI component w/in a circular region
      nhei = dblarr(ncols,nrows)+0      
      heitie = strarr(ncols,nrows)
      heitie[11,13:16]='HeI6678'
      heitie[12,12:17]='HeI6678'
      heitie[13,11:18]='HeI6678'
      heitie[14,11:18]='HeI6678'
      heitie[15,12:18]='HeI6678'
      heitie[16,12:16]='HeI6678'
      heitie[17,14:15]='HeI6678'
      heitiecol = intarr(ncols,nrows)+14
      heitierow = intarr(ncols,nrows)+14
      hei_zinit = dblarr(ncols,nrows,nad_maxncomp)
      hei_siginit = dblarr(ncols,nrows,nad_maxncomp)

      nnadabs = dblarr(ncols,nrows)
;      nnadabs[11,6] = 1
;      nnadabs[11,7:19] = 2
      nnadabs[12,4:19] = 2
      nnadabs[12,20:21] = 1
      nnadabs[13,4] = 1
      nnadabs[13,5:18] = 2
      nnadabs[13,19:20] = 1
      nadabs_zinit = dblarr(ncols,nrows,nad_maxncomp)+0.043
      nadabs_zinit[*,*,1] = 0.042
      nadabs_siginit = dblarr(ncols,nrows,nad_maxncomp)+100d
      nadabs_siginit[*,*,1] = 300d
      nadabs_siglim = [299792d/3000d/2.35d,1000d]

      nnadem = dblarr(ncols,nrows)
      nadem_zinit = dblarr(ncols,nrows,nad_maxncomp)+0.044d
      nadem_siginit = dblarr(ncols,nrows,nad_maxncomp)+150d
      nadem_finit = dblarr(ncols,nrows,nad_maxncomp)+0.1d
      nadem_rinit = dblarr(ncols,nrows,nad_maxncomp)+1.5d
      nadem_siglim = [299792d/3000d/2.35d,750d]
      nadem_fix = bytarr(ncols,nrows,nad_maxncomp,4)

      nnadem[12,0:5]=1
      nnadem[12,22:26]=1
;     Initialization from spaxel [13,5]
      nadem_fix[12,5,0,*] = [0b,1b,1b,1b]
      nadem_siginit[12,5,0] = 219.40d
      nadem_finit[12,5,0] = 0.0843d
      nadem_rinit[12,5,0] = 1d
      nnadem[13,0:4]=1
      nnadem[13,21:26]=1
;     Initialization from spaxel [14,4]
      nadem_fix[13,4,0,*] = [0b,1b,1b,1b]
      nadem_siginit[13,4,0] = 200.98d
      nadem_finit[13,4,0] = 0.0644d
      nadem_rinit[13,4,0] = 2.0093d
;      nnadem[16,*]=1
;      nnadem[16,8:14]=0
;      nnadem[18,*]=1
;      nnadem[19,*]=1
;      nnadem[21,*]=1

      initnad = {$
                 argsnadweq: {autowavelim: [6110,6160,6140,6180],$
                              autoindices:1},$
                 argsnormnad: {fitranlo: normnadlo,$
                               fitranhi: normnadhi},$
                 argspltnormnad: {fitranlo: normnadlo,$
                                  fitranhi: normnadhi,$
                                  pltran: pltnormnad},$
                 fcnfitnad: 'ifsf_nadfcn',$
                 fcninitpar: 'ifsf_initnad',$
                 fitran: [6080,6180],$
;                NaD absorption
                 nnadabs: nnadabs,$
                 nadabs_zinit: nadabs_zinit,$
                 nadabs_siginit: nadabs_siginit,$
                 nadabs_siglim: nadabs_siglim,$
;                NaD emission
                 nnadem: nnadem,$
                 nadem_zinit: nadem_zinit,$
                 nadem_siginit: nadem_siginit,$
                 nadem_finit: nadem_finit,$
                 nadem_rinit: nadem_rinit,$
                 nadem_siglim: nadem_siglim,$
                 nadem_fix: nadem_fix,$
;                HeI
                 nhei: nhei,$
                 hei_zinit: hei_zinit,$
                 hei_siginit: hei_siginit,$
                 heitiecol: heitiecol,$
                 heitierow: heitierow,$
                 heitie: heitie $
                }
   endif
                  
   return,init

end
