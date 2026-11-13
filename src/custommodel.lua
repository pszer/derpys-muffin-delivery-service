local custom_atts = require "cfg.custommodel"

require "modelmanager"
require "model"
require "facedecor"

CustomModel = {}
CustomModel.__index = CustomModel

function CustomModel:fromCfg(name)
	local props = custom_atts[name]
	if not props then
		error(string.format("CustomModel:fromCfg: no custom model %s found in cfg/custommodel", name))
	end
	return self:load(props)
end

function CustomModel:load(props)
	local model_name = props.model_name
	local model_face = props.model_face
	local model_outline = props.model_outline
	local model_outline_scale = props.model_outline_scale
	local model_rimlight = props.model_rimlight

	local model_outline_colour = props.model_outline_colour
	if model_outline_colour then
		model_outline_colour = {unpack(model_outline_colour)}
	end

	local model_ref = Models.loadModel(model_name)
	assert(model_ref)

	local decor,animface = nil,nil
	if model_face then
		decor,animface = faceFromCfg(model_face)
	end

	local inst = ModelInstance:newInstance(model_ref,
	{
		["model_i_outline_flag"] = model_outline,
		["model_i_outline_scale"] = model_outline_scale,
		["model_i_outline_colour"] = model_outline_colour,
		["model_i_rimlight"] = model_rimlight
	})

	inst:attachDecoration(decor)
	return inst
end
