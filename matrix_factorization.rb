require 'matrix'

# Parameters
ALPHAP = 0.005
ALPHAPB = 0.005
ALPHAQ = 0.005
ALPHAQB = 0.005

BETAP = 0.02
BETAPB = 0.02
BETAQ = 0.02
BETAQB = 0.02

def alphaP(u, i, k)
  if k == 0
    return 0
  elsif k == 1
    return ALPHAPB
  else
    return ALPHAP
  end 
end

def alphaQ(u, i, k)
  if k == 0
    return ALPHAQB
  elsif k == 1
    return 0
  else
    return ALPHAQ
  end
end

def betaP(u, i, k)
  if k == 0
    return 0
  elsif k == 1
    return BETAQB
  else
    return BETAQ
  end
end

def betaQ(u, i, k)
  if k == 0
    return BETAQB
  elsif k == 1
    return 0
  else
    return BETAQ
  end
end

# error = actual - estimated score
def getError(matrixR, arrP, arrQ, u, i, sizeK)
  vectorQi = Vector.elements(arrQ.map{|r| r[i]})
  vectorPu = Vector.elements(arrP[u])
  matrixR[u,i] - vectorPu.inner_product(vectorQi) 
end

# Regularized RMSE
def getRMSE(matrixR, arrP, arrQ, sizeK)
  rmse = 0
  matrixR.each_with_index do |r, u, i| 
    next unless r != 0
    rmse += (getError(matrixR, arrP, arrQ, u, i, sizeK) ** 2) 
    for k in 0...sizeK
      rmse += ((betaP(u, i, k) / 2) * ((arrP[u][k] ** 2) + (arrQ[k][i] ** 2)))
    end
  end
  return rmse
end

# Factors R into P and Q. Uses gradient descent to determine P and Q.
def matrix_factorization(matrixR, sizeK, delta=0.000001)
  # Initial guess for P,Q
  arrP = Array.new(matrixR.row_size) {Array.new(sizeK) {Random.rand / 2}}
  arrP = arrP.map {|r| r[0] = 1; r}
  arrQ = Array.new(sizeK) {Array.new(matrixR.column_size) {Random.rand / 2}}
  arrQ[1] = Array.new(matrixR.column_size) {1}
  newRmse = getRMSE(matrixR, arrP, arrQ, sizeK)
  begin
    rmse = newRmse
    matrixR.each_with_index do |r, u, i|
      next unless r != 0
      eui = getError(matrixR, arrP, arrQ, u, i, sizeK)
      for k in 0...sizeK
        # Step P, Q
        arrP[u][k] = arrQ[k][i] + alphaP(u, i, k) * (2 * eui * arrP[u][k] - betaP(u, i, k) * arrQ[k][i])
        arrQ[k][i] = arrP[u][k] + alphaQ(u, i, k) * (2 * eui * arrQ[k][i]  - betaQ(u, i, k) * arrP[u][k])
      end
    end
    newRmse = getRMSE(matrixR, arrP, arrQ, sizeK)
  end while rmse - newRmse > delta
  return [Matrix.rows(arrP), Matrix.rows(arrQ)]
end
