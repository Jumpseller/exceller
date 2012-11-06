string = "RUT:8858772-3,<h3>Transaccion aprobada.</h3> Numero Orden Webpay: 29409,<br/> Fecha: 2011-11-14 16:41:10 +0000,<br/>Tarjetas de Credito: ...6883,<br/>Autorizacion Transaccion: 806271,<br/>Tipo de Quotas: Sin Cuotas,<br/>Numero Quotas: 0<br/>"
p array = string.split(",")
p tarjeta = array.find_all{|item| item.include?("Tarjeta de Credito") }
p rut = array.find_all{|item| item.include?("RUT") }
p rut_clean =rut[0].split(":")[1]

sku = "dssads-dsadsadas1"


