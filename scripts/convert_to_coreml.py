import coremltools as ct
import onnx

onnx_model = onnx.load("DentalAI/Resources/Models/dental_model.onnx")
mlmodel = ct.converters.onnx.convert(
    model=onnx_model,
    minimum_deployment_target=ct.target.iOS16,
    compute_units=ct.ComputeUnit.ALL
)
mlmodel.save("DentalAI/Resources/Models/DentalModel.mlmodel")
print("✅ Saved CoreML model to DentalAI/Resources/Models/DentalModel.mlmodel")
