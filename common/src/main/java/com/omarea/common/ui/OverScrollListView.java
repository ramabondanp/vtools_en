package com.omarea.common.ui;

import android.content.Context;
import android.util.AttributeSet;
import android.widget.ListView;

public class OverScrollListView extends ListView {
    private int mMaxOverScrollY = 400;

    public OverScrollListView(Context context) {
        super(context);
    }

    public OverScrollListView(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public OverScrollListView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    public OverScrollListView(Context context, AttributeSet attrs, int defStyleAttr, int defStyleRes) {
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
