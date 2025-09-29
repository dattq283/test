import streamlit as st
import pandas as pd
import datetime
import calendar
import plotly.express as px
import numpy as np

# --- 1. CONFIGURATION AND UTILITIES ---

# Thiết lập cấu hình trang
st.set_page_config(layout="wide", page_title="FineBank.IO Dashboard", page_icon="🏦")

# Định nghĩa màu sắc và icons cho giao diện
TAILWIND_COLORS = {
    'teal_500': '#14b8a6',
    'teal_400': '#2dd4bf',
    'red_500': '#ef4444',
    'green_500': '#22c55e',
    'blue_500': '#3b82f6',
    'gray_700': '#374151',
    'gray_800': '#1f2937',
    'gray_100': '#f3f4f6',
    'gray_200': '#e5e7eb',  # 👈 thêm dòng này
    'gray_300': '#d1d5db',
    'yellow_500': '#f59e0b',
    'pink_500': '#ec4899',
    'violet_500': '#8b5cf6',
    'indigo_500': '#6366f1',
    'emerald_500': '#10b981',
}

CATEGORY_ICONS = {
    'food': '🍜', 'transport': '🚌', 'shopping': '🛍️', 'housing': '🏠',
    'entertainment': '🎬', 'healthcare': '⚕️', 'education': '🎓', 'salary': '💼', 'other': '📌'
}

CATEGORY_COLORS = {
    'housing': {'name': 'Nhà ở', 'color': TAILWIND_COLORS['blue_500']},
    'food': {'name': 'Thực phẩm', 'color': TAILWIND_COLORS['emerald_500']},
    'shopping': {'name': 'Mua sắm', 'color': TAILWIND_COLORS['pink_500']},
    'transport': {'name': 'Vận tải', 'color': TAILWIND_COLORS['yellow_500']},
    'entertainment': {'name': 'Giải trí', 'color': TAILWIND_COLORS['violet_500']},
    'healthcare': {'name': 'Y tế', 'color': TAILWIND_COLORS['red_500']},
    'education': {'name': 'Giáo dục', 'color': TAILWIND_COLORS['indigo_500']},
    'salary': {'name': 'Lương (Thu)', 'color': TAILWIND_COLORS['teal_500']},
    'other': {'name': 'Khác', 'color': TAILWIND_COLORS['gray_300']}
}

# Hàm tiện ích
def format_currency(amount):
    """Định dạng tiền tệ sang $"""
    return f"${amount:,.2f}"

def get_transaction_icon(category):
    """Lấy icon cho danh mục"""
    return CATEGORY_ICONS.get(category, '❓')

def get_category_name(category):
    """Lấy tên tiếng Việt của danh mục"""
    return CATEGORY_COLORS.get(category, {}).get('name', category.capitalize())

def load_data():
    """Tải dữ liệu giả lập và chuyển sang DataFrame"""
    raw_data = {
        datetime.date(2023, 5, 1): [
            {'id': 10, 'type': 'income', 'amount': 3500, 'category': 'salary', 'description': 'Lương'},
            {'id': 11, 'type': 'expense', 'amount': 1200, 'category': 'housing', 'description': 'Thuê nhà'}
        ],
        datetime.date(2023, 5, 5): [
            {'id': 12, 'type': 'income', 'amount': 3000, 'category': 'other', 'description': 'Thưởng'},
            {'id': 13, 'type': 'expense', 'amount': 1500, 'category': 'shopping', 'description': 'Mua sắm'}
        ],
        datetime.date(2023, 5, 10): [
            {'id': 14, 'type': 'income', 'amount': 1800, 'category': 'other', 'description': 'Hoàn tiền'},
            {'id': 15, 'type': 'expense', 'amount': 2500, 'category': 'food', 'description': 'Ăn uống'}
        ],
        datetime.date(2023, 5, 15): [
            {'id': 16, 'type': 'expense', 'amount': 1200, 'category': 'transport', 'description': 'Đi lại'}
        ],
        datetime.date(2023, 5, 20): [
            {'id': 17, 'type': 'income', 'amount': 2800, 'category': 'other', 'description': 'Đầu tư'},
            {'id': 18, 'type': 'expense', 'amount': 800, 'category': 'entertainment', 'description': 'Giải trí'}
        ],
        datetime.date(2023, 5, 25): [
            {'id': 19, 'type': 'income', 'amount': 3000, 'category': 'salary', 'description': 'Tạm ứng'},
            {'id': 20, 'type': 'expense', 'amount': 1000, 'category': 'shopping', 'description': 'Mua sắm'}
        ],
        datetime.date(2023, 5, 19): [
            {'id': 1, 'type': 'expense', 'description': 'Cà phê sáng tại Starbucks', 'amount': 5.00, 'category': 'food'},
            {'id': 2, 'type': 'income', 'description': 'Quà tặng sinh nhật', 'amount': 50.00, 'category': 'other'}
        ],
    }
    return raw_data

def get_df_from_state():
    """Tạo DataFrame từ session state cho việc tính toán và vẽ biểu đồ"""
    all_data = []
    for date, transactions in st.session_state.transactions.items():
        for t in transactions:
            all_data.append({
                'date': date,
                'id': t['id'],
                'type': t['type'],
                'amount': t['amount'],
                'category': t['category'],
                'description': t['description']
            })
    df = pd.DataFrame(all_data)
    if not df.empty:
        df['month'] = df['date'].apply(lambda x: x.replace(day=1))
    return df

# --- 2. STATE INITIALIZATION ---

if 'transactions' not in st.session_state:
    st.session_state.transactions = load_data()
if 'current_date' not in st.session_state:
    st.session_state.current_date = datetime.date(2023, 5, 19) # Ngày giả lập
if 'next_id' not in st.session_state:
    st.session_state.next_id = 25

# Lấy DataFrame
df_transactions = get_df_from_state()

# --- 3. CUSTOM CSS STYLING ---

def inject_css():
    """Tiêm CSS để mô phỏng Tailwind và bố cục card"""
    custom_css = f"""
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap');
        
        body {{ font-family: 'Inter', sans-serif; background-color: {TAILWIND_COLORS['gray_100']}; }}

        /* Tùy chỉnh Streamlit Main Container */
        .stApp {{ background-color: {TAILWIND_COLORS['gray_100']}; }}
        .main-content {{ padding: 32px; }}
        
        /* CARD STYLES */
        div[data-testid="stVerticalBlock"] > [data-testid^="stHorizontalBlock"] {{
            border-radius: 16px;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
            background-color: white;
            padding: 24px;
            margin-bottom: 24px;
        }}
        
        /* Calendar Container & Buttons */
        .calendar-grid {{
            display: grid;
            grid-template-columns: repeat(7, 1fr);
            gap: 4px;
            text-align: center;
        }}

        .stButton>button {{
            width: 100%;
            height: 48px;
            border-radius: 8px;
            font-weight: 500;
            transition: all 0.2s;
            border: 1px solid {TAILWIND_COLORS['gray_300']};
        }}
        
        .stButton>button:hover:not(.selected-day) {{
            background-color: {TAILWIND_COLORS['gray_100']};
            border: 1px solid {TAILWIND_COLORS['teal_500']};
        }}

        /* Selected Day Style */
        .selected-day {{
            background-color: {TAILWIND_COLORS['blue_500']} !important;
            color: white !important;
            font-weight: 700 !important;
            border: 2px solid {TAILWIND_COLORS['blue_500']} !important;
        }}
        
        /* Today Style */
        .today-day {{
            border: 2px solid {TAILWIND_COLORS['blue_500']} !important;
            background-color: #eff6ff !important;
            color: {TAILWIND_COLORS['gray_700']} !important;
        }}
        
        /* Sidebar Styling */
        [data-testid="stSidebar"] {{
            background-color: {TAILWIND_COLORS['gray_800']};
            color: white;
            padding: 24px;
        }}
        
        /* Sidebar Link Active */
        .sidebar-active-link {{
            background-color: {TAILWIND_COLORS['teal_500']} !important;
            color: white !important;
            padding: 16px;
            border-radius: 12px;
            position: relative;
            font-weight: 600;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }}
        .sidebar-link {{
            color: {TAILWIND_COLORS['gray_300']};
            padding: 16px;
            border-radius: 12px;
        }}
        .sidebar-link:hover {{
            background-color: {TAILWIND_COLORS['gray_700']};
            color: white;
        }}
        
        /* Transaction Detail Styling */
        .transaction-detail {{
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 12px;
            border-radius: 8px;
            margin-bottom: 8px;
            border: 1px solid {TAILWIND_COLORS['gray_200']};
            background-color: white;
            transition: all 0.2s;
        }}
        .transaction-detail:hover {{
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.05);
            transform: translateY(-1px);
        }}
        .icon-box {{
            width: 32px;
            height: 32px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 16px;
            margin-right: 12px;
        }}
        .expense-icon {{ background-color: #fee2e2; color: {TAILWIND_COLORS['red_500']}; }}
        .income-icon {{ background-color: #d1fae5; color: {TAILWIND_COLORS['green_500']}; }}
        .amount-expense {{ color: {TAILWIND_COLORS['red_500']}; font-weight: 700; }}
        .amount-income {{ color: {TAILWIND_COLORS['green_500']}; font-weight: 700; }}
        
        /* Legend Item Style */
        .legend-item {{
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 4px 0;
            font-size: 0.875rem;
        }}
    </style>
    """
    st.markdown(custom_css, unsafe_allow_html=True)

# Gọi hàm tiêm CSS
inject_css()

# --- 4. LAYOUT COMPONENTS ---

def render_sidebar():
    """Hiển thị Sidebar"""
    st.sidebar.markdown(f"""
    <div style="padding: 10px 0 30px 0; text-align: center;">
        <span style="font-size: 28px; font-weight: 800; color: white;">FINEbank.<span style="color: {TAILWIND_COLORS['teal_400']}; font-weight: 700;">IO</span></span>
    </div>
    <ul style="list-style-type: none; padding: 0;">
        <li class="sidebar-active-link" style="margin-bottom: 8px;">
            <i class="fas fa-th-large mr-3"></i>Tổng quan
        </li>
        <li class="sidebar-link" style="margin-bottom: 8px;">
            <i class="fas fa-balance-scale-left mr-3"></i>Số dư
        </li>
        <li class="sidebar-link" style="margin-bottom: 8px;">
            <i class="fas fa-exchange-alt mr-3"></i>Giao dịch
        </li>
        <li class="sidebar-link" style="margin-bottom: 8px;">
            <i class="fas fa-file-invoice-dollar mr-3"></i>Hóa đơn
        </li>
    </ul>
    """, unsafe_allow_html=True)
    
    st.sidebar.markdown('<div style="margin-top: 100px; border-top: 1px solid #4b5563;"></div>', unsafe_allow_html=True)
    st.sidebar.button("⚙️ Cài đặt", use_container_width=True)
    st.sidebar.button("➡️ Đăng xuất", use_container_width=True)
    st.sidebar.info("Tanzir Rahman (TR)", icon="👤")

def render_header():
    """Hiển thị Header"""
    col1, col2 = st.columns([3, 1])
    
    with col1:
        st.markdown('<h1 style="font-size: 28px; font-weight: 700; color: #1f2937;">Xin chào, Tanzir</h1>', unsafe_allow_html=True)
    
    with col2:
        # Streamlit doesn't support complex inline elements like the original, so we use simpler widgets
        st.text_input("Tìm kiếm ở đây", placeholder="Tìm kiếm...", label_visibility="collapsed")
        
    st.markdown("---")

def render_weekly_stats():
    """Mô phỏng Thống kê Tuần (Dùng placeholder tĩnh)"""
    st.markdown('<h3 style="font-size: 20px; font-weight: 600; color: #374151; margin-bottom: 16px;">Thống kê Tuần</h3>', unsafe_allow_html=True)
    
    # Placeholder cho biểu đồ cột
    cols = st.columns(7)
    heights = [60, 85, 70, 95, 65, 40, 80]
    colors = [TAILWIND_COLORS['teal_500'], TAILWIND_COLORS['red_500'], TAILWIND_COLORS['teal_500'], TAILWIND_COLORS['red_500'], TAILWIND_COLORS['teal_500'], TAILWIND_COLORS['red_500'], TAILWIND_COLORS['teal_500']]
    labels = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]

    for i in range(7):
        with cols[i]:
            st.markdown(f"""
            <div style="height: 80px; width: 20px; background-color: {TAILWIND_COLORS['gray_300']}; border-radius: 4px; position: relative; margin: 0 auto;">
                <div style="position: absolute; bottom: 0; width: 100%; background-color: {colors[i]}; height: {heights[i]}%; border-radius: 4px 4px 0 0;"></div>
            </div>
            <div style="text-align: center; font-size: 12px; color: {TAILWIND_COLORS['gray_700']}; margin-top: 4px;">{labels[i]}</div>
            """, unsafe_allow_html=True)


# --- 5. CHART RENDERING FUNCTIONS ---

def render_category_pie_chart():
    """Render Biểu đồ tròn phân tích chi phí theo danh mục (Yêu cầu mới)"""
    
    # Lọc dữ liệu trong tháng hiện tại và là chi phí
    current_month_start = st.session_state.current_date.replace(day=1)
    
    df_current_month = df_transactions[
        (df_transactions['month'] == current_month_start) & 
        (df_transactions['type'] == 'expense')
    ]
    
    category_summary = df_current_month.groupby('category')['amount'].sum().reset_index()
    category_summary['category_name'] = category_summary['category'].apply(get_category_name)
    category_summary['color'] = category_summary['category'].apply(lambda c: CATEGORY_COLORS.get(c, {}).get('color', TAILWIND_COLORS['gray_300']))
    
    total_expense = category_summary['amount'].sum()
    
    st.markdown('<h3 style="font-size: 20px; font-weight: 600; color: #374151; margin-bottom: 16px;">Phân tích Chi phí theo Danh mục</h3>', unsafe_allow_html=True)

    if total_expense == 0:
        st.markdown(f'<div style="text-align: center; color: {TAILWIND_COLORS["gray_500"]}; padding: 30px;">Chưa có chi phí nào trong tháng này.</div>', unsafe_allow_html=True)
        return

    # Biểu đồ Doughnut Plotly
    fig = px.pie(
        category_summary,
        values='amount',
        names='category_name',
        hole=.7, # Tạo Doughnut Chart
        color='category_name',
        color_discrete_map={row['category_name']: row['color'] for index, row in category_summary.iterrows()},
        height=300
    )

    fig.update_traces(
        textinfo='none', # Tắt nhãn trên biểu đồ
        hovertemplate="<b>%{label}</b><br>%{value:$,.2f}<br>%{percent}<extra></extra>"
    )
    
    fig.update_layout(
        margin=dict(t=0, b=0, l=0, r=0),
        showlegend=False, # Tắt legend mặc định
        plot_bgcolor='white',
        paper_bgcolor='white',
        height=250,
        annotations=[dict(text=f'Tổng Chi: {format_currency(total_expense)}', x=0.5, y=0.5, font_size=14, showarrow=False)]
    )
    
    st.plotly_chart(fig, use_container_width=True)
    
    # Custom Legend (Chú thích)
    st.markdown('<div style="font-size: 14px; margin-top: 10px;">', unsafe_allow_html=True)
    for index, row in category_summary.sort_values(by='amount', ascending=False).iterrows():
        percent = (row['amount'] / total_expense) * 100
        st.markdown(f"""
        <div class="legend-item">
            <div style="display: flex; align-items: center;">
                <span style="display: inline-block; width: 10px; height: 10px; border-radius: 50%; background-color: {row['color']}; margin-right: 8px;"></span>
                <span>{row['category_name']}</span>
            </div>
            <span style="font-weight: 700; color: {TAILWIND_COLORS['gray_800']};">{format_currency(row['amount'])} ({percent:.1f}%)</span>
        </div>
        """, unsafe_allow_html=True)
    st.markdown('</div>', unsafe_allow_html=True)


def render_monthly_area_chart():
    """Render Biểu đồ Thu Chi Hàng Tháng"""
    st.markdown('<h3 style="font-size: 20px; font-weight: 600; color: #374151; margin-bottom: 16px;">Biểu đồ Thu Chi Hàng Tháng</h3>', unsafe_allow_html=True)

    current_month_start = st.session_state.current_date.replace(day=1)
    
    df_current_month = df_transactions[df_transactions['month'] == current_month_start]
    
    # Chuẩn bị dữ liệu cho biểu đồ đường
    daily_summary = df_current_month.groupby(['date', 'type'])['amount'].sum().unstack(fill_value=0).reset_index()
    
    if daily_summary.empty:
        st.warning(f"Chưa có giao dịch nào trong {current_month_start.strftime('%B %Y')}.")
        return

    # Tên cột
    if 'income' not in daily_summary.columns:
        daily_summary['income'] = 0
    if 'expense' not in daily_summary.columns:
        daily_summary['expense'] = 0

    # Biểu đồ Plotly
    fig = px.area(
        daily_summary,
        x='date',
        y='income',
        markers=True,
        line_shape='spline',
        color_discrete_sequence=[TAILWIND_COLORS['teal_500']],
        title='Thu nhập Hàng ngày'
    )
    
    # Thêm đường Chi phí
    fig.add_scatter(
        x=daily_summary['date'],
        y=daily_summary['expense'],
        mode='lines',
        name='Chi phí',
        line=dict(color=TAILWIND_COLORS['gray_300'], dash='dash'),
        line_shape='spline'
    )

    fig.update_layout(
        xaxis_title="",
        yaxis_title="Số tiền ($)",
        hovermode="x unified",
        legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="right", x=1),
        plot_bgcolor='white',
        paper_bgcolor='white',
        margin=dict(t=10, b=10, l=10, r=10),
        yaxis=dict(gridcolor=TAILWIND_COLORS['gray_100'], showgrid=True),
        xaxis=dict(gridcolor=TAILWIND_COLORS['gray_100'], showgrid=False)
    )
    
    fig.update_traces(
        fill='to zero',
        opacity=0.5,
        hovertemplate="Ngày %{x|%d}: %{y:$,.2f}<extra></extra>"
    )

    st.plotly_chart(fig, use_container_width=True)


def render_recent_transactions():
    """Hiển thị 4 giao dịch gần đây nhất"""
    st.markdown('<h3 style="font-size: 20px; font-weight: 600; color: #374151; margin-bottom: 16px;">Giao dịch gần đây</h3>', unsafe_allow_html=True)
    
    if df_transactions.empty:
        st.info("Chưa có giao dịch nào.")
        return

    recent_df = df_transactions.sort_values(by='date', ascending=False).head(4)

    for index, row in recent_df.iterrows():
        is_expense = row['type'] == 'expense'
        amount_color = TAILWIND_COLORS['red_500'] if is_expense else TAILWIND_COLORS['green_500']
        icon_class = 'expense-icon' if is_expense else 'income-icon'
        sign = '-' if is_expense else '+'
        
        st.markdown(f"""
        <div class="transaction-detail">
            <div style="display: flex; align-items: center;">
                <div class="icon-box {icon_class}">
                    {get_transaction_icon(row['category'])}
                </div>
                <div>
                    <div style="font-weight: 600; font-size: 14px; color: {TAILWIND_COLORS['gray_800']};">{row['description']}</div>
                    <div style="font-size: 12px; color: {TAILWIND_COLORS['gray_500']};">{get_category_name(row['category'])} - {row['date'].strftime('%d/%m/%Y')}</div>
                </div>
            </div>
            <span style="color: {amount_color}; font-weight: 700;">{sign} {format_currency(row['amount'])}</span>
        </div>
        """, unsafe_allow_html=True)


# --- 6. CALENDAR AND FORM LOGIC ---

def change_month_action(delta):
    """Thay đổi tháng hiện tại và cập nhật lại selected_date"""
    new_date = st.session_state.current_date.replace(day=1) + pd.DateOffset(months=delta)
    st.session_state.current_date = new_date.date()
    # Sau khi chuyển tháng, mặc định chọn ngày 1 của tháng mới
    st.session_state.selected_date = st.session_state.current_date.replace(day=1)
    st.experimental_rerun()

def select_day_action(day):
    """Chọn một ngày cụ thể trên lịch"""
    try:
        new_date = st.session_state.current_date.replace(day=day)
    except ValueError:
        # Xử lý trường hợp tháng không có ngày này (ví dụ: ngày 31 cho tháng 2)
        new_date = st.session_state.current_date.replace(day=calendar.monthrange(st.session_state.current_date.year, st.session_state.current_date.month)[1])
    
    st.session_state.selected_date = new_date
    st.experimental_rerun()

def delete_transaction(date_key, tx_id):
    """Xóa giao dịch và cập nhật state"""
    date_key = pd.to_datetime(date_key).date()
    
    if date_key in st.session_state.transactions:
        # Lọc giao dịch cần xóa
        st.session_state.transactions[date_key] = [
            t for t in st.session_state.transactions[date_key] if t['id'] != tx_id
        ]
        # Xóa key nếu không còn giao dịch nào
        if not st.session_state.transactions[date_key]:
            del st.session_state.transactions[date_key]
    
    st.experimental_rerun()

def add_transaction_form(date_key):
    """Hiển thị form thêm giao dịch"""
    date_key_str = date_key.strftime('%d/%m/%Y')
    
    with st.expander(f"➕ Thêm giao dịch ngày {date_key_str}", expanded=True):
        with st.form("add_transaction_form", clear_on_submit=True):
            tx_type = st.selectbox("Loại giao dịch", options=['expense', 'income'], format_func=lambda x: 'Chi tiêu' if x == 'expense' else 'Thu nhập')
            amount = st.number_input("Số tiền ($)", min_value=0.01, format="%.2f")
            description = st.text_input("Mô tả")
            category = st.selectbox("Danh mục", options=list(CATEGORY_ICONS.keys()), format_func=get_category_name)
            
            submitted = st.form_submit_button("💾 Lưu giao dịch", type="primary")

            if submitted:
                if amount > 0 and description:
                    new_transaction = {
                        'id': st.session_state.next_id,
                        'type': tx_type,
                        'amount': amount,
                        'category': category,
                        'description': description
                    }
                    
                    if date_key not in st.session_state.transactions:
                        st.session_state.transactions[date_key] = []
                    
                    st.session_state.transactions[date_key].append(new_transaction)
                    st.session_state.next_id += 1
                    st.success(f"Đã thêm giao dịch {format_currency(amount)} vào ngày {date_key_str}")
                    st.experimental_rerun()
                else:
                    st.error("Vui lòng nhập số tiền hợp lệ và mô tả.")

def render_calendar_and_daily_detail():
    """Hiển thị Lịch và Chi tiết giao dịch hàng ngày"""
    
    # Lấy thông tin tháng
    current_date = st.session_state.current_date
    year = current_date.year
    month = current_date.month
    selected_date = st.session_state.selected_date if 'selected_date' in st.session_state else current_date
    today_date = datetime.date.today()
    
    st.markdown('<h3 style="font-size: 20px; font-weight: 700; color: #374151;">Lịch Thu Chi</h3>', unsafe_allow_html=True)
    
    # Header Lịch (Chuyển tháng)
    col_l, col_m, col_r = st.columns([1, 2, 1])
    with col_l:
        st.button("❮", on_click=change_month_action, args=(-1,), key='prev_month', use_container_width=True)
    with col_m:
        st.markdown(f'<div style="text-align: center; font-weight: 700; font-size: 16px; margin: 0 auto; padding-top: 5px;">{calendar.month_name[month]} {year}</div>', unsafe_allow_html=True)
    with col_r:
        st.button("❯", on_click=change_month_action, args=(1,), key='next_month', use_container_width=True)
    
    st.markdown("<hr style='margin: 8px 0;'>", unsafe_allow_html=True)
    
    # Ngày trong tuần
    days_of_week = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"]
    day_cols = st.columns(7)
    for i, day in enumerate(days_of_week):
        day_cols[i].markdown(f'<div style="text-align: center; font-weight: 600; font-size: 12px; color: {TAILWIND_COLORS["gray_500"]};">{day}</div>', unsafe_allow_html=True)

    # Lưới Lịch
    cal = calendar.Calendar(firstweekday=6) # Bắt đầu tuần từ Chủ Nhật
    month_days = cal.monthdayscalendar(year, month)
    
    for week in month_days:
        cols = st.columns(7)
        for i, day in enumerate(week):
            with cols[i]:
                if day != 0:
                    current_day_date = datetime.date(year, month, day)
                    date_key = current_day_date
                    
                    # Xác định style
                    is_selected = date_key == selected_date
                    is_today = date_key == today_date
                    
                    # CSS Classes
                    css_class = ""
                    if is_selected:
                        css_class += "selected-day"
                    elif is_today:
                        css_class += "today-day"
                    
                    # Kiểm tra Thu/Chi
                    has_expense = date_key in st.session_state.transactions and any(t['type'] == 'expense' for t in st.session_state.transactions[date_key])
                    has_income = date_key in st.session_state.transactions and any(t['type'] == 'income' for t in st.session_state.transactions[date_key])
                    
                    indicators = ""
                    if has_expense or has_income:
                        indicators += '<div style="position: absolute; bottom: 4px; left: 50%; transform: translateX(-50%); display: flex; gap: 3px;">'
                        if has_expense:
                            indicators += f'<span style="width: 5px; height: 5px; border-radius: 50%; background-color: {TAILWIND_COLORS["red_500"]};"></span>'
                        if has_income:
                            indicators += f'<span style="width: 5px; height: 5px; border-radius: 50%; background-color: {TAILWIND_COLORS["green_500"]};"></span>'
                        indicators += '</div>'

                    # Nút bấm ngày
                    st.markdown(f"""
                    <div style="position: relative;">
                        <button class='{css_class}' style='width: 100%;' onclick="window.parent.document.querySelector('button[key=day_{day}]').click()">
                            {day}
                            {indicators}
                        </button>
                    </div>
                    """, unsafe_allow_html=True)
                    st.button(f"", key=f'day_{day}', on_click=select_day_action, args=(day,), help=f"Chọn ngày {day}", use_container_width=True)
    
    # Chi tiết giao dịch hàng ngày
    st.markdown("---")
    st.markdown(f'<h3 style="font-size: 20px; font-weight: 700; color: {TAILWIND_COLORS["gray_700"]}; margin-bottom: 8px;">Chi tiết giao dịch</h3>', unsafe_allow_html=True)
    st.markdown(f'<p style="font-size: 14px; color: {TAILWIND_COLORS["gray_500"]}; margin-bottom: 16px;">Giao dịch ngày <span style="font-weight: 600; color: {TAILWIND_COLORS["teal_500"]};">{selected_date.strftime("%d/%m/%Y")}</span></p>', unsafe_allow_html=True)
    
    # Hiển thị giao dịch của ngày đã chọn
    daily_transactions = st.session_state.transactions.get(selected_date, [])
    
    if not daily_transactions:
        st.markdown(f'<div style="text-align: center; color: {TAILWIND_COLORS["gray_500"]}; padding: 30px;"><i class="fas fa-wallet" style="font-size: 32px; margin-bottom: 8px;"></i><p>Không có giao dịch nào.</p></div>', unsafe_allow_html=True)
    else:
        for tx in daily_transactions:
            is_expense = tx['type'] == 'expense'
            amount_color = TAILWIND_COLORS['red_500'] if is_expense else TAILWIND_COLORS['green_500']
            icon_class = 'expense-icon' if is_expense else 'income-icon'
            sign = '-' if is_expense else '+'
            
            col_tx, col_del = st.columns([5, 1])
            
            with col_tx:
                st.markdown(f"""
                <div class="transaction-detail">
                    <div style="display: flex; align-items: center;">
                        <div class="icon-box {icon_class}" style="flex-shrink: 0;">
                            {get_transaction_icon(tx['category'])}
                        </div>
                        <div>
                            <div style="font-weight: 600; font-size: 14px; color: {TAILWIND_COLORS['gray_800']};">{tx['description']}</div>
                            <div style="font-size: 12px; color: {TAILWIND_COLORS['gray_500']};">{get_category_name(tx['category'])}</div>
                        </div>
                    </div>
                    <span style="color: {amount_color}; font-weight: 700; flex-shrink: 0;">{sign} {format_currency(tx['amount'])}</span>
                </div>
                """, unsafe_allow_html=True)
            
            with col_del:
                st.button("🗑️", key=f"del_{tx['id']}_{selected_date}", help="Xóa giao dịch", on_click=delete_transaction, args=(selected_date, tx['id']), use_container_width=True)
    
    # Thêm form
    st.markdown("---")
    add_transaction_form(selected_date)


# --- 7. MAIN DASHBOARD RENDER ---

def render_dashboard():
    """Hàm chính để render toàn bộ dashboard"""
    render_header()
    
    # Chia bố cục chính (3 cột cho content, 1 cột cho lịch -> 3/1 ratio)
    col_content, col_sidebar_right = st.columns([3, 1])
    
    with col_content:
        # Hàng 1: Biểu đồ tròn và Thống kê tuần (3 cột)
        st.markdown(f'<div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 24px; padding: 0;">', unsafe_allow_html=True)
        
        # Biểu đồ tròn (Card 1/3)
        st.markdown(f'<div class="card-1-3" style="grid-column: span 1;">', unsafe_allow_html=True)
        render_category_pie_chart()
        st.markdown('</div>', unsafe_allow_html=True)

        # Thống kê Tuần (Card 2/3)
        st.markdown(f'<div class="card-2-3" style="grid-column: span 2;">', unsafe_allow_html=True)
        render_weekly_stats()
        st.markdown('</div>', unsafe_allow_html=True)
        
        st.markdown('</div>', unsafe_allow_html=True) # Kết thúc div 3 cột

        # Hàng 2: Biểu đồ Thu Chi Hàng Tháng (Card 3/3)
        with st.container():
            st.markdown('<div class="card">', unsafe_allow_html=True)
            render_monthly_area_chart()
            st.markdown('</div>', unsafe_allow_html=True)

        # Hàng 3: Giao dịch Gần đây
        with st.container():
            st.markdown('<div class="card">', unsafe_allow_html=True)
            render_recent_transactions()
            st.markdown('</div>', unsafe_allow_html=True)


    with col_sidebar_right:
        # Lịch và Chi tiết
        with st.container():
            st.markdown('<div class="card" style="padding: 24px;">', unsafe_allow_html=True)
            render_calendar_and_daily_detail()
            st.markdown('</div>', unsafe_allow_html=True)


    # render_sidebar() # Sidebar mặc định của Streamlit đã được styled
    

if __name__ == '__main__':
    render_dashboard()
