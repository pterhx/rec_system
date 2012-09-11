require 'matrix'

# error = actual - estimated score
def getError(matrixR, arrP, arrQ, u, i, sizeK)
  vectorPu, vectorQi = Vector.elements(arrP[u]), Vector.elements(arrQ.map{|r| r[i]})
  matrixR[u,i] - vectorPu.inner_product(vectorQi) 
end

# Regularized RMSE
def getRMSE(matrixR, arrP, arrQ, sizeK, beta)
  rmse = 0
  matrixR.each_with_index do |r, u, i| 
    next unless r != 0
    rmse += (getError(matrixR, arrP, arrQ, u, i, sizeK) ** 2) 
    for k in 0...sizeK
      rmse += ((beta / 2) * ((arrP[u][k] ** 2) + (arrQ[k][i] ** 2)))
    end
  end
  return rmse
end

# Factors R into P and Q. Uses gradient descent to determine P and Q.
def matrix_factorization(matrixR, sizeK, alpha=0.005, beta=0.02, delta=0.000001)
  # Initial guess for P,Q
  arrP = Array.new(matrixR.row_size) {Array.new(sizeK) {Random.rand}}
  arrQ = Array.new(sizeK) {Array.new(matrixR.column_size) {Random.rand}}
  newRmse = getRMSE(matrixR, arrP, arrQ, sizeK, beta)
  begin
    rmse = newRmse
    matrixR.each_with_index do |r, u, i|
      next unless r != 0
      eui = getError(matrixR, arrP, arrQ, u, i, sizeK)
      for k in 0...sizeK
        # Step P, Q
        arrP[u][k] = arrQ[k][i] + alpha * (2 * eui * arrP[u][k] - beta * arrQ[k][i])
        arrQ[k][i] = arrP[u][k] + alpha * (2 * eui * arrQ[k][i]  - beta * arrP[u][k])
      end
    end
    newRmse = getRMSE(matrixR, arrP, arrQ, sizeK, beta)
  end while rmse - newRmse > delta
  return [Matrix.rows(arrP), Matrix.rows(arrQ)]
end
