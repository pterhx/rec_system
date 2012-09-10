require 'matrix'

def printMatrix m1
  m1.to_a.each {|r| puts r.inspect}
end

def getError(matrixR, matrixP, matrixQ, u, i, sizeK)
  matrixR[u,i] - matrixP.row_vectors[u].inner_product(matrixQ.column_vectors[i]) 
end

def getRMSE(matrixR, matrixP, matrixQ, sizeK, beta)
  sum = 0
  matrixR.each_with_index do |r, u, i| 
    next unless r != 0
    sum += (getError(matrixR, matrixP, matrixQ, u, i, sizeK) ** 2) 
    for k in 0...sizeK
      sum += ((beta / 2) * ((matrixP[u,k] ** 2) + (matrixQ[k,i] ** 2)))
    end
  end
  return sum
end

def stepQ(matrixP, matrixQ, eui, u, i, k, alpha, beta)
  matrixQ[k][i] + alpha * (2 * eui * matrixP[u][k] - beta * matrixQ[k][i])
end

def stepP(matrixP, matrixQ, eui, u, i, k, alpha, beta)
  matrixP[u][k] + alpha * (2 * eui * matrixQ[k][i]  - beta * matrixP[u][k])
end

def matrix_factorization(matrixR, matrixP0, matrixQ0, sizeK, alpha=0.001, beta=0.02, delta=0.0005)
  puts "Start matrix_factorization"
  matrixP = matrixP0
  matrixQ = matrixQ0
  newR = matrixP * matrixQ
  newTotalE = getRMSE(matrixR, matrixP, matrixQ, sizeK, beta)
  totalE = 0
  begin
    totalE = newTotalE
    newPArr = matrixP.to_a
    newQArr = matrixQ.to_a
    matrixR.each_with_index do |r, u, i|
      next unless r != 0
      eui = getError(matrixR, matrixP, matrixQ, u, i, sizeK)
      for k in 0...sizeK
        newPArr[u][k] = stepP(newPArr, newQArr, eui, u, i, k, alpha, beta)
        newQArr[k][i] = stepQ(newPArr, newQArr, eui, u, i, k, alpha, beta)
      end
    end

    matrixP = Matrix.rows(newPArr)
    matrixQ = Matrix.rows(newQArr)
    newR = matrixP * matrixQ
    newTotalE = getRMSE(matrixR, matrixP, matrixQ, sizeK, beta)
    # puts "Delta: #{totalE - newTotalE}"
  end while totalE - newTotalE > delta
  return newR
end
