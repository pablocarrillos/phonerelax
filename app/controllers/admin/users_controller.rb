module Admin
  # Gestión de administradores del panel (por ahora todos con el mismo rol).
  class UsersController < BaseController
    before_action :set_user, only: [ :edit, :update, :destroy ]

    def index
      @users = User.order(:email_address)
    end

    def new
      @user = User.new
    end

    def create
      @user = User.new(user_params)
      if @user.save
        redirect_to admin_users_path, notice: "Administrador creado."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      attrs = user_params
      # Si no se escribe contraseña nueva, se conserva la actual.
      attrs = attrs.except(:password, :password_confirmation) if attrs[:password].blank?
      password_changed = attrs[:password].present?
      if @user.update(attrs)
        # al cambiar la contraseña caen todas sus sesiones abiertas (menos la
        # actual si es la propia cuenta): una cookie robada deja de valer
        keep = (@user == Current.user ? Current.session : nil)
        @user.sessions.where.not(id: keep&.id).destroy_all if password_changed
        redirect_to admin_users_path, notice: "Administrador actualizado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @user == Current.user
        redirect_to admin_users_path, alert: "No puedes borrar tu propio usuario."
      elsif User.count <= 1
        redirect_to admin_users_path, alert: "Debe quedar al menos un administrador."
      else
        @user.destroy
        redirect_to admin_users_path, notice: "Administrador borrado."
      end
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:name, :email_address, :password, :password_confirmation)
    end
  end
end
