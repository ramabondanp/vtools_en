package com.omarea.common.ui;

import android.content.Context;
import android.util.AttributeSet;
import android.widget.ScrollView;

public class OverScrollView extends ScrollView {
    private int mMaxOverScrollY = 400;

    public OverScrollView(Context context) {
        super(context);
    }

    public OverScrollView(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public OverScrollView(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);
    }

    public OverScrollView(Context context, AttributeSet attrs, int defStyleAttr, int defStyleRes) {
        super(context, attrs, defStyleAttr, defStyleRes);
    }

    public void setMaxOverScrollY(int maxOverScrollY) {
        this.mMaxOverScrollY = maxOverScrollY;
    }

    @Override
    protected boolean overScrollBy(int deltaX, int deltaY, int scrollX, int scrollY, int scrollRangeX,
                                   int scrollRangeY, int maxOverScrollX, int maxOverScrollY,
                                   boolean isTouchEvent) {
        return super.overScrollBy(deltaX, deltaY, scrollX, scrollY, scrollRangeX, scrollRangeY,
                maxOverScrollX, mMaxOverScrollY, isTouchEvent);
    }
}
