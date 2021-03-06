; docformat = 'rst'
;
;+
;
;  Compute intrinsic flux and its error from the Cardelli, Clayton, &
;  Mathis (1989) extinction curve.
;  
;  Root equation is
;      m_i = m_o - (A/A_V * E(B-V) * R_V)
;
;  Substitute fluxes for mags. to get the equations in the source code.
;
; :Categories:
;    IFSFIT
;
; :Returns:
;    N x 1 or N x 2 array, where N is the number of input spectra and the other
;    dimension is the intrinsic flux (and its error, if fluxerr and/or
;    ebverr are specified).
;
; :Params:
;    lambda: in, required, type=double
;      Rest wavelength of line for which to compute extinction correction.
;    flux: in, required, type=dblarr(N)
;      Line fluxes.
;    ebv: in, required, type=dblarr(N)
;      Extinctions.
;
; :Keywords:
;    rv: in, optional, type=double, default=3.1
;      R_V = A_V / E(B-V)
;    fluxerr: in, optional, type=dblarr(N)
;      Flux errors.
;    ebverr: in, optional, type=dblarr(N)
;      Errors in E(B-V)
;    relative: in, optional, type=byte
;      Compute dust correction relative to another wavelength. In this case, 
;      the input wavelength array should have two elements.
;    tran: in, optional, type=byte
;      Transpose the output error array.
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
;      2009sep08, DSNR, created
;      2015apr17, DSNR, copied to IFSFIT package; added documentation, license,
;                       and copyright
;
; :Copyright:
;    Copyright (C) 2014 David S. N. Rupke
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
function ifsf_dustcor_ccm,lambda,flux,ebv,rv=rv,fluxerr=fluxerr,$
                          ebverr=ebverr,relative=relative,tran=tran

   if ~ keyword_set(rv) then rv=3.1d

   alamav = extcurve_ccm(lambda,rv=rv)
   if keyword_set(relative) then coeff = 0.4d *(alamav[0]-alamav[1])*rv $
   else coeff = 0.4d * alamav[0] * rv

;  Only apply extinction correction if calculated extinction is greater
;  than 0.
   posebv = where(ebv ge 0,ctpos)
   negebv = where(ebv lt 0,ctneg)

;  Fluxes
   fint = dblarr(n_elements(ebv))
   finterr = dblarr(n_elements(ebv))
   if ctpos gt 0 then $
      fint[posebv] = flux[posebv] * 10d^(coeff * ebv[posebv])
   if ctneg gt 0 then $
      fint[negebv] = flux[negebv]

;  Errors
   doerr=0
   if keyword_set(fluxerr) then begin
      doerr=1
      if ctpos gt 0 then $
         finterr[posebv] += fluxerr[posebv] * 10d^(coeff * ebv[posebv])
      if ctneg gt 0 then $
         finterr[negebv] = fluxerr[negebv]
   endif
   if keyword_set(ebverr) then begin
      doerr=1
      if ctpos gt 0 then $
         finterr[posebv] += ebverr[posebv] * flux[posebv] * coeff * $
                            alog(10d) * exp(coeff * alog(10d) * $
                            ebv[posebv])
      if ctneg gt 0 then $
         finterr[negebv] = fluxerr[negebv]
   endif
   if doerr then begin
      fint = [[fint],[finterr]]
      if n_elements(flux) eq 1 AND keyword_set(tran) then fint = transpose(fint)
   endif

   return,fint

end
