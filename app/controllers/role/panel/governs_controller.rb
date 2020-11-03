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

  def namespaces
    @busyness = Busyness.find_by identifier: params[:business_identifier]
    @name_spaces = @busyness.name_spaces
  end

  def governs
    q_params = {}
    q_params.merge! params.permit(:business_identifier, :namespace_identifier)

    @governs = Govern.default_where(q_params)
  end

  def rules
    q_params = {}
    q_params.merge! params.permit(:controller_identifier)

    @rules = Rule.default_where(q_params)
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
