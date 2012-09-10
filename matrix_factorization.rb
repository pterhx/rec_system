require 'matrix'

def getError(matrixR, arrP, arrQ, u, i, sizeK)
  vectorPu = Vector.elements(arrP[u])
  vectorQi = Vector.elements(arrQ.map{|r| r[i]})
  matrixR[u,i] - vectorPu.inner_product(vectorQi) 
end

def getRMSE(matrixR, arrP, arrQ, sizeK, beta)
  sum = 0
  matrixR.each_with_index do |r, u, i| 
    next unless r != 0
    sum += (getError(matrixR, arrP, arrQ, u, i, sizeK) ** 2) 
    for k in 0...sizeK
      sum += ((beta / 2) * ((arrP[u][k] ** 2) + (arrQ[k][i] ** 2)))
    end
  end
  return sum
end

def stepQ(arrP, arrQ, eui, u, i, k, alpha, beta)
  arrQ[k][i] + alpha * (2 * eui * arrP[u][k] - beta * arrQ[k][i])
end

def stepP(arrP, arrQ, eui, u, i, k, alpha, beta)
  arrP[u][k] + alpha * (2 * eui * arrQ[k][i]  - beta * arrP[u][k])
end

def matrix_factorization(matrixR, matrixP0, matrixQ0, sizeK, alpha=0.001, beta=0.02, delta=0.0005)
  puts "Start matrix_factorization"
  arrP, arrQ = matrixP0.to_a, matrixQ0.to_a
  newTotalE = getRMSE(matrixR, arrP, arrQ, sizeK, beta)
  totalE = 0
  begin
    totalE = newTotalE
    matrixR.each_with_index do |r, u, i|
      next unless r != 0
      eui = getError(matrixR, arrP, arrQ, u, i, sizeK)
      for k in 0...sizeK
        arrP[u][k] = stepP(arrP, arrQ, eui, u, i, k, alpha, beta)
        arrQ[k][i] = stepQ(arrP, arrQ, eui, u, i, k, alpha, beta)
      end
    end
    newTotalE = getRMSE(matrixR, arrP, arrQ, sizeK, beta)
  end while totalE - newTotalE > delta
  return Matrix.rows(arrP) * Matrix.rows(arrQ)
end
