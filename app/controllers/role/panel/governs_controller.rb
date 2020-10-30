class Role::Panel::GovernsController < Role::Panel::BaseController
  before_action :set_govern, only: [:show, :edit, :update, :move_higher, :move_lower, :destroy]

  def index
    q_params = {}
    q_params.merge! params.permit(:business_identifier, :namespace_identifier)

    @busynesses = Busyness.all

    @governs = Govern.includes(:rules).default_where(q_params).page(params[:page])
  end

  def sync
    Govern.sync
  end

  def namespace
    @busyness = Busyness.find_by identifier: params[:business_identifier]
    identifiers = Govern.unscope(:order).select(:namespace_identifier).where(business_identifier: params[:business_identifier]).distinct.pluck(:namespace_identifier)
    @name_spaces = NameSpace.where(identifier: identifiers)
  end

  def remove
    @busyness = Busyness.find_by identifier: params[:business_identifier]
  end

  def show
  end

  def edit
  end

  def update
    @govern.assign_attributes(govern_params)

    unless @govern.save
      render :edit, locals: { model: @govern }, status: :unprocessable_entity
    end
  end

  def move_higher
    @govern.move_higher
  end

  def move_lower
    @govern.move_lower
  end

  private
  def set_govern
    @govern = Govern.find(params[:id])
  end

  def govern_params
    params.fetch(:govern, {}).permit(
      :position
    )
  end

end
