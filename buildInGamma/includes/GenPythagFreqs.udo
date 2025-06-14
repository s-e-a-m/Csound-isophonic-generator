opcode GenPythagFreqs, i, iiii
  iFund, iNumIntervals, iNumOctaves, iTblNum xin
  iTotalLen = iNumIntervals * iNumOctaves
  iFreqs[] init iTotalLen
  
  iOctave = 0
  iBaseIndex = 0
  
  while iOctave < iNumOctaves do
    ; Inizializza il primo rapporto per questa ottava
    iFifth = 3/2
    iFreqs[iBaseIndex] = iFund * (2^iOctave)
    
    ; Genera la serie di quinte per questa ottava
    indx = 1
    iLastRatio = 1
    while (indx < iNumIntervals) do
      iRatio = iLastRatio * iFifth
      ; Riduci all'ottava di riferimento
      while (iRatio >= 2) do
        iRatio = iRatio / 2
      od
      iFreqs[iBaseIndex + indx] = iFund * iRatio * (2^iOctave)
      iLastRatio = iRatio
      indx += 1
    od
    
    ; Ordina le frequenze per questa ottava
    indx = iBaseIndex
    while (indx < (iBaseIndex + iNumIntervals - 1)) do
      indx2 = indx + 1
      while (indx2 < (iBaseIndex + iNumIntervals)) do
        if (iFreqs[indx2] < iFreqs[indx]) then
          iTemp = iFreqs[indx]
          iFreqs[indx] = iFreqs[indx2]
          iFreqs[indx2] = iTemp
        endif
        indx2 += 1
      od
      indx += 1
    od
    
    iBaseIndex += iNumIntervals
    iOctave += 1
  od

  iTotalLen = iNumIntervals * iNumOctaves
  iIndx = 0
  while (iIndx < iTotalLen) do
    tabw_i iFreqs[iIndx], iIndx, iTblNum
    iIndx += 1
  od
  
  ;debug
  if iOctave == iNumOctaves then
    iRes = 1
  else
    iRes = 0
  endif
  
  xout iRes
endop

